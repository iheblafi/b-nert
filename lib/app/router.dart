import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/absence/absence_screen.dart';
import '../features/auth/state/session.dart';
import '../features/auth/ui/forgot_password_screen.dart';
import '../features/auth/ui/no_access_screen.dart';
import '../features/auth/ui/session_gate_screens.dart';
import '../features/auth/ui/sign_in_screen.dart';
import '../features/history/history_screen.dart';
import '../features/more/more_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/time_entry/ui/entry_form_screen.dart';
import '../features/times/model/records.dart';
import '../features/times/times_screen.dart';
import 'shell/app_shell.dart';
import 'shell/fading_branches.dart';

const _publicPaths = {'/sign-in', '/forgot-password'};

/// Where a session state belongs; null means "stay where you are".
String? redirectFor(SessionState session, String path) => switch (session) {
  SessionLoading() => path == '/loading' ? null : '/loading',
  SignedOut() => _publicPaths.contains(path) ? null : '/sign-in',
  NoAccess() => path == '/no-access' ? null : '/no-access',
  ContextFailed() => path == '/context-failed' ? null : '/context-failed',
  SignedIn() =>
    _publicPaths.contains(path) ||
            const {'/loading', '/no-access', '/context-failed'}.contains(path)
        ? '/times'
        : null,
};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<SessionState>(ref.read(sessionProvider));
  ref
    ..listen(sessionProvider, (_, next) => refresh.value = next)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/times',
    refreshListenable: refresh,
    redirect: (context, state) =>
        redirectFor(refresh.value, state.matchedLocation),
    routes: [
      GoRoute(path: '/loading', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/no-access', builder: (_, _) => const NoAccessScreen()),
      GoRoute(
        path: '/context-failed',
        builder: (_, _) => const ContextFailedScreen(),
      ),
      GoRoute(
        path: '/entry/new',
        builder: (_, state) => EntryFormScreen(
          day: switch (state.uri.queryParameters['date']) {
            final String d? => DateTime.tryParse('${d}T00:00:00Z'),
            _ => null,
          },
        ),
      ),
      GoRoute(
        path: '/entry/edit',
        builder: (_, state) => switch (state.extra) {
          final TimeRecord e => EntryFormScreen(entry: e),
          _ => const EntryFormScreen(),
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      StatefulShellRoute(
        builder: (_, _, shell) => AppShell(shell: shell),
        // Tabs cross-fade instead of cutting; each keeps its state.
        navigatorContainerBuilder: (_, shell, children) =>
            FadingBranches(index: shell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/times', builder: (_, _) => const TimesScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (_, _) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/absence',
                builder: (_, _) => const AbsenceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
