import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../user_context/model/user_context.dart';
import '../../user_context/state/user_context_controller.dart';
import '../data/auth_repository.dart';

sealed class SessionState {
  const SessionState();
}

final class SessionLoading extends SessionState {
  const SessionLoading();
}

final class SignedOut extends SessionState {
  const SignedOut([this.reason]);

  /// Why the user was signed out without asking, shown on the sign-in screen.
  final AppFailure? reason;
}

final class SignedIn extends SessionState {
  const SignedIn(this.user, this.context);
  final AuthUser user;
  final UserContext context;
}

/// Signed in, but no licence or role for time tracking (spec F1, AC3).
final class NoAccess extends SessionState {
  const NoAccess(this.user);
  final AuthUser user;
}

/// Signed in, but settings and permissions could not be loaded.
final class ContextFailed extends SessionState {
  const ContextFailed(this.user, this.failure);
  final AuthUser user;
  final AppFailure failure;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw StateError('authRepositoryProvider not overridden'),
);

class SessionController extends Notifier<SessionState> {
  StreamSubscription<UserContext>? _contextSub;
  String? _userId;

  // Read once in build: async work may finish after this notifier is
  // disposed, and Ref must not be used then.
  late AuthRepository _auth;
  late UserContextController _contexts;

  void _set(SessionState next) {
    if (ref.mounted) state = next;
  }

  @override
  SessionState build() {
    _auth = ref.watch(authRepositoryProvider);
    _contexts = ref.watch(userContextControllerProvider);
    final sub = _auth.events.listen(_onEvent);
    ref.onDispose(() {
      unawaited(sub.cancel());
      unawaited(_contextSub?.cancel());
    });
    final user = _auth.currentUser;
    if (user == null) return const SignedOut();
    Future.microtask(() => _loadContext(user));
    _userId = user.id;
    return const SessionLoading();
  }

  void _onEvent(AuthEvent event) {
    switch (event) {
      case SignedInEvent(:final user):
        // Token refreshes repeat the same user; nothing to reload.
        if (user.id == _userId && state is! SignedOut) return;
        _userId = user.id;
        _set(const SessionLoading());
        unawaited(_loadContext(user));
      case SignedOutEvent(:final reason):
        unawaited(_clearLocal());
        _set(SignedOut(reason));
    }
  }

  Future<void> _loadContext(AuthUser user) async {
    // Not awaited: a cancelled subscription delivers nothing more, and
    // waiting for the old stream to wind down delayed the retry.
    unawaited(_contextSub?.cancel());
    _contextSub = _contexts
        .load(user.id)
        .listen(
          (ctx) {
            if (_userId != user.id) return;
            _set(
              ctx.access.hasTimeTracking ? SignedIn(user, ctx) : NoAccess(user),
            );
          },
          onError: (Object e) {
            if (_userId != user.id) return;
            _set(ContextFailed(user, AppFailure.from(e)));
          },
        );
  }

  /// Retry after [ContextFailed], and refresh when the app returns to the
  /// foreground (spec section 4.3).
  Future<void> refreshContext() async {
    final user = switch (state) {
      SignedIn(:final user) || NoAccess(:final user) => user,
      ContextFailed(:final user) => user,
      _ => null,
    };
    if (user == null) return;
    if (state is ContextFailed) _set(const SessionLoading());
    await _loadContext(user);
  }

  /// Sign out on request: tokens and cached personal data are removed
  /// (spec F1, AC10). Reminders are stopped here once they exist (sprint 3).
  Future<void> signOut() async {
    await _auth.signOut();
    await _clearLocal();
    _set(const SignedOut());
  }

  Future<void> _clearLocal() async {
    _userId = null;
    unawaited(_contextSub?.cancel());
    _contextSub = null;
    await _contexts.clear();
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);
