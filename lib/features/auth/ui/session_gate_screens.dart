import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/splash/animated_splash.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/offline_view.dart';
import '../../../core/design/state_views.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/l10n/l10n.dart';
import '../state/session.dart';

/// The loading route.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  /// The splash's end state with the clock hand turning: the same picture
  /// at start and while loading after sign-in.
  @override
  Widget build(BuildContext context) => const AnimatedSplash(skipIntro: true);
}

/// Signed in, but settings or permissions could not be loaded.
/// Without a connection that is the offline screen.
class ContextFailedScreen extends ConsumerWidget {
  const ContextFailedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    if (state is! ContextFailed) return const SplashScreen();
    final session = ref.read(sessionProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: state.failure is NoConnection
                  ? OfflineView(onRetry: session.refreshContext)
                  : ErrorView(
                      failure: state.failure,
                      onRetry: session.refreshContext,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(Gap.m),
              child: TextButton(
                onPressed: session.signOut,
                child: Text(context.l10n.signOut),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
