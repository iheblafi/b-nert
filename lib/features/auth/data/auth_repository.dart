import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';

class AuthUser {
  const AuthUser({required this.id, required this.email});
  final String id;
  final String email;
}

sealed class AuthEvent {
  const AuthEvent();
}

/// A session exists (sign in, restored at start, or token refreshed).
final class SignedInEvent extends AuthEvent {
  const SignedInEvent(this.user);
  final AuthUser user;
}

/// No session. [reason] is null when the user signed out on purpose.
final class SignedOutEvent extends AuthEvent {
  const SignedOutEvent([this.reason]);
  final AppFailure? reason;
}

abstract interface class AuthRepository {
  AuthUser? get currentUser;

  /// Session changes, including the silent token refresh done by the client.
  Stream<AuthEvent> get events;

  /// Throws [AppFailure], e.g. [InvalidCredentials].
  Future<void> signIn({required String email, required String password});

  /// Always ends signed out locally, even without a connection.
  Future<void> signOut();

  /// Completes normally whether or not the account exists (spec F1, AC7).
  /// Throws only [NoConnection].
  Future<void> requestPasswordReset(String email);
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  final GoTrueClient _auth;
  AppFailure? _lastError;

  static AuthUser _map(User u) => AuthUser(id: u.id, email: u.email ?? '');

  @override
  AuthUser? get currentUser => switch (_auth.currentUser) {
    final u? => _map(u),
    null => null,
  };

  @override
  Stream<AuthEvent> get events => _auth.onAuthStateChange.transform(
    StreamTransformer.fromHandlers(
      handleData: (state, sink) {
        final user = state.session?.user;
        if (user != null) {
          _lastError = null;
          sink.add(SignedInEvent(_map(user)));
        } else if (state.event == AuthChangeEvent.signedOut) {
          sink.add(SignedOutEvent(_reason(state.signOutReason)));
        }
      },
      // Refresh failures arrive as stream errors before the signedOut event.
      handleError: (error, _, _) => _lastError = AppFailure.from(error),
    ),
  );

  AppFailure? _reason(SignOutReason? reason) {
    if (reason == null || reason == SignOutReason.userInitiated) return null;
    final last = _lastError;
    _lastError = null;
    return last is AccountDisabled ? last : const SessionExpired();
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } on Object catch (e) {
      throw AppFailure.from(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on Object {
      // Local sign out has already removed the session; nothing to show.
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      // No redirectTo: GoTrue uses its site URL, the web app, where the user
      // sets the new password (spec F1, AC8).
      await _auth.resetPasswordForEmail(email.trim());
    } on Object catch (e) {
      final failure = AppFailure.from(e);
      if (failure is NoConnection) throw failure;
      // Any other answer (unknown user, rate limit) stays neutral.
    }
  }
}
