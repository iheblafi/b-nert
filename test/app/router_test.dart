import 'package:flutter_mobile/app/router.dart';
import 'package:flutter_mobile/core/errors/app_failure.dart';
import 'package:flutter_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_mobile/features/auth/state/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

void main() {
  const user = AuthUser(id: 'u1', email: 'a@b.de');
  final signedIn = SignedIn(user, userContext());

  test('signed out: only public screens', () {
    expect(redirectFor(const SignedOut(), '/times'), '/sign-in');
    expect(redirectFor(const SignedOut(), '/more'), '/sign-in');
    expect(redirectFor(const SignedOut(), '/sign-in'), isNull);
    expect(redirectFor(const SignedOut(), '/forgot-password'), isNull);
  });

  test('signed in: never on sign-in or gate screens', () {
    expect(redirectFor(signedIn, '/sign-in'), '/times');
    expect(redirectFor(signedIn, '/loading'), '/times');
    expect(redirectFor(signedIn, '/no-access'), '/times');
    expect(redirectFor(signedIn, '/more'), isNull);
    expect(redirectFor(signedIn, '/entry/new'), isNull);
  });

  test('gates', () {
    expect(redirectFor(const SessionLoading(), '/times'), '/loading');
    expect(redirectFor(const NoAccess(user), '/times'), '/no-access');
    expect(
      redirectFor(const ContextFailed(user, NoConnection()), '/times'),
      '/context-failed',
    );
  });
}
