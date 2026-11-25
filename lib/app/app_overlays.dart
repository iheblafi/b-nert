import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/design/app_theme.dart';
import '../core/design/motion.dart';
import '../core/design/offline_view.dart';
import '../core/network/network_status.dart';
import '../features/app_lock/app_lock.dart';
import '../features/app_lock/lock_screen.dart';
import '../features/auth/state/session.dart';
import 'splash/animated_splash.dart';

/// Screens that sit above the whole app, whatever the route: the animated
/// intro at start, the lock and offline screens, and the success check.
class AppOverlays extends ConsumerStatefulWidget {
  const AppOverlays({required this.child, this.splashStartedAt, super.key});

  final Widget child;
  final DateTime? splashStartedAt;

  @override
  ConsumerState<AppOverlays> createState() => _AppOverlaysState();
}

class _AppOverlaysState extends ConsumerState<AppOverlays>
    with SingleTickerProviderStateMixin {
  bool _introDone = false;
  bool _splashGone = false;

  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: SuccessBurst.duration,
  );

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(celebrationProvider, (_, _) => _burst.forward(from: 0));
    final session = ref.watch(sessionProvider);
    final loading = session is SessionLoading;
    final offline = ref.watch(onlineProvider).value == false;
    final locked = ref.watch(appLockProvider).locked && session is! SignedOut;
    final hideSplash = _introDone && !loading;
    if (hideSplash && !ref.read(splashDoneProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(splashDoneProvider.notifier).done();
      });
    }

    // Default bars for every screen; the splash and offline screen set
    // their own while shown. Without this the splash's light icons stay
    // behind on white screens.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemBarsFor(Theme.of(context)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: offline
                ? OfflineScreen(
                    key: const ValueKey('offline'),
                    onRetry: () {
                      ref.invalidate(onlineProvider);
                      ref.read(sessionProvider.notifier).refreshContext();
                    },
                  )
                : const SizedBox.shrink(key: ValueKey('online')),
          ),
          // Above the offline screen: unlocking works without a network.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: locked
                ? LockScreen(
                    key: const ValueKey('locked'),
                    autoPrompt: _splashGone,
                  )
                : const SizedBox.shrink(key: ValueKey('unlocked')),
          ),
          AnimatedBuilder(
            animation: _burst,
            builder: (_, _) => _burst.isAnimating
                ? SuccessBurst(t: _burst.value)
                : const SizedBox.shrink(),
          ),
          if (!_splashGone)
            IgnorePointer(
              ignoring: hideSplash,
              child: AnimatedOpacity(
                opacity: hideSplash ? 0 : 1,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeIn,
                onEnd: () {
                  if (hideSplash) setState(() => _splashGone = true);
                },
                child: AnimatedScale(
                  scale: hideSplash ? 1.08 : 1,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeIn,
                  child: AnimatedSplash(
                    stillLoading: loading,
                    startedAt: widget.splashStartedAt,
                    onIntroDone: () => setState(() => _introDone = true),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
