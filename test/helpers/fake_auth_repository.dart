import 'dart:async';

import 'package:flutter_mobile/core/errors/app_failure.dart';
import 'package:flutter_mobile/features/auth/data/auth_repository.dart';

/// In-memory auth backend. [password] is the only accepted one.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user, this.resetError});

  AuthUser? user;
  AppFailure? resetError;
  String password = 'Geheim1!';
  final resetRequests = <String>[];
  int signOutCalls = 0;
  final _events = StreamController<AuthEvent>.broadcast();

  @override
  AuthUser? get currentUser => user;

  @override
  Stream<AuthEvent> get events => _events.stream;

  /// Simulates what the client does on its own, e.g. a failed refresh.
  void emit(AuthEvent e) {
    user = switch (e) {
      SignedInEvent(:final user) => user,
      SignedOutEvent() => null,
    };
    _events.add(e);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (password != this.password) throw const InvalidCredentials();
    emit(SignedInEvent(AuthUser(id: 'u1', email: email.trim())));
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    emit(const SignedOutEvent());
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    resetRequests.add(email);
    if (resetError != null) throw resetError!;
  }
}
