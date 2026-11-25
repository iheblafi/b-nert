import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/motion.dart';
import '../../core/l10n/l10n.dart';
import '../auth/state/session.dart';
import 'app_lock.dart';

/// Covers the app until the user unlocks with fingerprint, face or the
/// screen lock. Prompts by itself once [autoPrompt] is true.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({this.autoPrompt = true, super.key});

  final bool autoPrompt;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _prompted = false;
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _maybeAutoPrompt();
  }

  @override
  void didUpdateWidget(LockScreen old) {
    super.didUpdateWidget(old);
    _maybeAutoPrompt();
  }

  void _maybeAutoPrompt() {
    if (!widget.autoPrompt || _prompted) return;
    _prompted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy || !mounted) return;
    setState(() => _busy = true);
    final ok = await ref
        .read(appLockProvider.notifier)
        .unlock(context.l10n.lockReason);
    if (ok) {
      ref.read(celebrationProvider.notifier).celebrate();
    } else {
      Haptics.error();
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _failed = !ok;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AnnotatedRegion(
      value: systemBarsFor(theme),
      child: Material(
        key: const Key('lockScreen'),
        color: scheme.surface,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Gap.l),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primaryContainer,
                      ),
                      child: Icon(
                        Icons.fingerprint,
                        size: 88,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: Gap.xl),
                    Text(
                      l.lockTitle,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Gap.m),
                    Text(
                      l.lockBody,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_failed) ...[
                      const SizedBox(height: Gap.m),
                      Text(
                        l.unlockFailed,
                        key: const Key('unlockFailed'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: Gap.xl),
                    PressScale(
                      child: FilledButton.icon(
                        key: const Key('unlock'),
                        onPressed: _busy ? null : _unlock,
                        icon: const Icon(Icons.fingerprint),
                        label: Text(l.unlock),
                      ),
                    ),
                    const SizedBox(height: Gap.s),
                    TextButton(
                      key: const Key('usePassword'),
                      onPressed: () =>
                          ref.read(sessionProvider.notifier).signOut(),
                      child: Text(l.usePassword),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// After a password sign-in: offer the lock once (spec 2.2, moved up).
Future<void> maybeOfferAppLock(BuildContext context, WidgetRef ref) async {
  final lock = ref.read(appLockProvider.notifier);
  if (!await lock.takeOffer() || !context.mounted) return;
  final l = context.l10n;
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('appLockOffer'),
      icon: const Icon(Icons.fingerprint, size: 40),
      title: Text(l.offerTitle),
      content: Text(l.offerBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.offerLater),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.offerEnable),
        ),
      ],
    ),
  );
  if ((yes ?? false) && context.mounted) await enableAppLock(context, ref);
}

/// Turns the lock on after confirming the screen lock; says so when it
/// did not work instead of failing silently.
Future<void> enableAppLock(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ok = await ref.read(appLockProvider.notifier).enable(l.enableReason);
  if (!ok) {
    messenger?.showSnackBar(SnackBar(content: Text(l.enableFailed)));
  }
}
