import 'package:flutter_mobile/core/errors/app_failure.dart';
import 'package:flutter_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_mobile/features/auth/state/session.dart';
import 'package:flutter_mobile/features/user_context/state/user_context_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/test_app.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeContextRepository contexts;
  late ProviderContainer container;

  ProviderContainer make() {
    final c = ProviderContainer(overrides: testOverrides(auth, contexts));
    addTearDown(c.dispose);
    c.listen(sessionProvider, (_, _) {});
    return c;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    auth = FakeAuthRepository();
    contexts = FakeContextRepository();
  });

  test('no stored session: signed out', () {
    container = make();
    expect(container.read(sessionProvider), isA<SignedOut>());
  });

  test('stored session: loading, then signed in (AC1)', () async {
    auth.user = const AuthUser(id: 'u1', email: 'a@b.de');
    container = make();
    expect(container.read(sessionProvider), isA<SessionLoading>());
    await settle();
    await settle();
    expect(container.read(sessionProvider), isA<SignedIn>());
  });

  test(
    'sign in loads the context once; token refresh does not reload',
    () async {
      container = make();
      await auth.signIn(email: 'a@b.de', password: auth.password);
      await settle();
      await settle();
      expect(container.read(sessionProvider), isA<SignedIn>());
      expect(contexts.loads, 1);

      auth.emit(const SignedInEvent(AuthUser(id: 'u1', email: 'a@b.de')));
      await settle();
      expect(contexts.loads, 1);
      expect(container.read(sessionProvider), isA<SignedIn>());
    },
  );

  test('no licence or role: NoAccess (AC3)', () async {
    contexts.result = userContext(roles: {});
    container = make();
    await auth.signIn(email: 'a@b.de', password: auth.password);
    await settle();
    await settle();
    expect(container.read(sessionProvider), isA<NoAccess>());
  });

  test('context cannot load: ContextFailed, retry recovers', () async {
    contexts.result = const NoConnection();
    container = make();
    await auth.signIn(email: 'a@b.de', password: auth.password);
    await settle();
    await settle();
    final failed = container.read(sessionProvider);
    expect(failed, isA<ContextFailed>());
    expect((failed as ContextFailed).failure, isA<NoConnection>());

    contexts.result = userContext();
    await container.read(sessionProvider.notifier).refreshContext();
    await settle();
    await settle();
    expect(container.read(sessionProvider), isA<SignedIn>());
  });

  test(
    'failed refresh of a disabled account signs out with reason (AC4, AC5)',
    () async {
      container = make();
      await auth.signIn(email: 'a@b.de', password: auth.password);
      await settle();
      await settle();
      auth.emit(const SignedOutEvent(AccountDisabled()));
      await settle();
      final s = container.read(sessionProvider);
      expect(s, isA<SignedOut>());
      expect((s as SignedOut).reason, isA<AccountDisabled>());
    },
  );

  test('sign out removes the session and the cached context (AC10)', () async {
    container = make();
    await auth.signIn(email: 'a@b.de', password: auth.password);
    await settle();
    await settle();
    final cache = container.read(userContextCacheProvider);
    expect(await cache.read('u1'), isNotNull);

    await container.read(sessionProvider.notifier).signOut();
    expect(container.read(sessionProvider), isA<SignedOut>());
    expect((container.read(sessionProvider) as SignedOut).reason, isNull);
    expect(auth.signOutCalls, 1);
    expect(auth.user, isNull);
    expect(await cache.read('u1'), isNull);
  });
}
