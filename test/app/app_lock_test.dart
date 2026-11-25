import 'package:flutter_mobile/core/l10n/language.dart';
import 'package:flutter_mobile/features/app_lock/app_lock.dart';
import 'package:flutter_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/test_app.dart';

void main() {
  FakeAuthRepository signedIn() => FakeAuthRepository(
    user: const AuthUser(id: 'u1', email: 'a@b.de'),
  );

  Future<void> pump(
    WidgetTester tester,
    FakeAuthRepository auth,
    FakeBiometrics bio, {
    bool lockEnabled = false,
  }) => pumpFullApp(
    tester,
    auth,
    null,
    const [Locale('de', 'DE')],
    AppLanguage.system,
    null,
    bio,
    lockEnabled,
  );

  final lockScreen = find.byKey(const Key('lockScreen'));
  final home = find.byKey(const Key('newEntry'));

  Future<bool?> storedLock() =>
      SharedPreferencesAsync().getBool(AppLockStore.enabledKey);

  Future<void> signInWithPassword(
    WidgetTester tester,
    FakeAuthRepository auth,
  ) async {
    await tester.enterText(find.byKey(const Key('email')), 'anna@firma.de');
    await tester.enterText(find.byKey(const Key('password')), auth.password);
    await tester.tap(find.text('Anmelden'));
    await tester.pumpAndSettle();
  }

  testWidgets('lock on and a stored session: the app opens locked and asks '
      'for the fingerprint by itself', (tester) async {
    final bio = FakeBiometrics(result: false);
    await pump(tester, signedIn(), bio, lockEnabled: true);

    expect(lockScreen, findsOneWidget);
    expect(find.text('App gesperrt'), findsOneWidget);
    expect(bio.prompts, 1);
    // A failed or cancelled prompt says what to do next.
    expect(find.byKey(const Key('unlockFailed')), findsOneWidget);

    bio.result = true;
    await tester.tap(find.byKey(const Key('unlock')));
    await tester.pumpAndSettle();
    expect(lockScreen, findsNothing);
    expect(home, findsOneWidget);
  });

  testWidgets('a successful fingerprint at start goes straight in', (
    tester,
  ) async {
    await pump(tester, signedIn(), FakeBiometrics(), lockEnabled: true);
    expect(lockScreen, findsNothing);
    expect(home, findsOneWidget);
  });

  testWidgets('"Mit Passwort anmelden" signs out but keeps the lock on', (
    tester,
  ) async {
    final auth = signedIn();
    await pump(tester, auth, FakeBiometrics(result: false), lockEnabled: true);
    await tester.tap(find.byKey(const Key('usePassword')));
    await tester.pumpAndSettle();

    expect(lockScreen, findsNothing);
    expect(find.text('Anmelden'), findsWidgets);
    expect(auth.user, isNull);
    // Not switched off (this test starts with the lock on in memory only).
    expect(await storedLock(), isNot(false));
  });

  Future<void> enableAfterPasswordSignIn(
    WidgetTester tester,
    FakeAuthRepository auth,
  ) async {
    await signInWithPassword(tester, auth);
    await tester.tap(find.text('Aktivieren'));
    await tester.pumpAndSettle();
  }

  Future<void> signOutViaMore(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Mehr'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signOut')));
    await tester.pumpAndSettle();
  }

  final quick = find.byKey(const Key('quickSignIn'));

  testWidgets('after signing out, signing in again takes only the '
      'fingerprint or PIN', (tester) async {
    final auth = FakeAuthRepository();
    final bio = FakeBiometrics();
    await pump(tester, auth, bio);
    await enableAfterPasswordSignIn(tester, auth);
    expect(testSecrets.values.keys, contains(SavedSignIn.key));

    await signOutViaMore(tester);
    expect(auth.user, isNull);
    expect(quick, findsOneWidget);

    await tester.tap(quick);
    await tester.pumpAndSettle();
    expect(home, findsOneWidget);
    expect(auth.user?.email, 'anna@firma.de');
    expect(bio.prompts, 2);
  });

  testWidgets('cancelling the prompt does not sign in', (tester) async {
    final auth = FakeAuthRepository();
    final bio = FakeBiometrics();
    await pump(tester, auth, bio);
    await enableAfterPasswordSignIn(tester, auth);
    await signOutViaMore(tester);

    bio.result = false;
    await tester.tap(quick);
    await tester.pumpAndSettle();
    expect(auth.user, isNull);
    expect(quick, findsOneWidget);
  });

  testWidgets('a changed password drops the saved sign-in with a notice', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await pump(tester, auth, FakeBiometrics());
    await enableAfterPasswordSignIn(tester, auth);
    await signOutViaMore(tester);

    auth.password = 'Neu-Geheim2!';
    await tester.tap(quick);
    await tester.pumpAndSettle();
    expect(auth.user, isNull);
    expect(find.byKey(const Key('signInNotice')), findsOneWidget);
    expect(quick, findsNothing);
    expect(testSecrets.values.keys, isNot(contains(SavedSignIn.key)));
  });

  testWidgets('another person signing in with a password removes the saved '
      'sign-in and is asked for themselves', (tester) async {
    final auth = FakeAuthRepository();
    await pump(tester, auth, FakeBiometrics());
    await enableAfterPasswordSignIn(tester, auth);
    await signOutViaMore(tester);

    await tester.enterText(find.byKey(const Key('email')), 'ben@firma.de');
    await tester.enterText(find.byKey(const Key('password')), auth.password);
    await tester.tap(find.text('Anmelden'));
    await tester.pumpAndSettle();

    expect(testSecrets.values.keys, isNot(contains(SavedSignIn.key)));
    expect(find.byKey(const Key('appLockOffer')), findsOneWidget);
  });

  testWidgets('turning the lock off deletes the saved sign-in', (tester) async {
    final auth = FakeAuthRepository();
    await pump(tester, auth, FakeBiometrics());
    await enableAfterPasswordSignIn(tester, auth);
    await tester.tap(find.bySemanticsLabel('Mehr'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appLockSwitch')));
    await tester.pumpAndSettle();

    expect(await storedLock(), isFalse);
    expect(testSecrets.values.keys, isNot(contains(SavedSignIn.key)));
  });

  testWidgets('lock off: no lock screen, no prompt', (tester) async {
    final bio = FakeBiometrics();
    await pump(tester, signedIn(), bio);
    expect(lockScreen, findsNothing);
    expect(bio.prompts, 0);
  });

  testWidgets('after a password sign-in the lock is offered once; '
      'accepting asks for the fingerprint and turns it on', (tester) async {
    final auth = FakeAuthRepository();
    final bio = FakeBiometrics();
    await pump(tester, auth, bio);
    await signInWithPassword(tester, auth);

    expect(find.byKey(const Key('appLockOffer')), findsOneWidget);
    await tester.tap(find.text('Aktivieren'));
    await tester.pumpAndSettle();

    expect(bio.prompts, 1);
    expect(await storedLock(), isTrue);
    expect(home, findsOneWidget);
  });

  testWidgets('"Später" leaves it off and does not ask again', (tester) async {
    final auth = FakeAuthRepository();
    await pump(tester, auth, FakeBiometrics());
    await signInWithPassword(tester, auth);
    await tester.tap(find.text('Später'));
    await tester.pumpAndSettle();
    expect(await storedLock(), isNot(true));

    // Leave and come back to the home screen: no second offer.
    await tester.tap(find.bySemanticsLabel('Mehr'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Zeiten'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appLockOffer')), findsNothing);
  });

  testWidgets('no fingerprint on the device: no offer and no switch', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await pump(tester, auth, FakeBiometrics(available: false));
    await signInWithPassword(tester, auth);
    expect(find.byKey(const Key('appLockOffer')), findsNothing);

    await tester.tap(find.bySemanticsLabel('Mehr'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appLockSwitch')), findsNothing);
  });

  testWidgets('the switch under Mehr turns the lock on and off', (
    tester,
  ) async {
    final bio = FakeBiometrics();
    await pump(tester, signedIn(), bio);
    await tester.tap(find.bySemanticsLabel('Mehr'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('appLockSwitch')));
    await tester.pumpAndSettle();
    expect(bio.prompts, 1);
    expect(await storedLock(), isTrue);

    await tester.tap(find.byKey(const Key('appLockSwitch')));
    await tester.pumpAndSettle();
    expect(await storedLock(), isFalse);
  });

  testWidgets('back from the background after 2 minutes: locked again; '
      'after a short switch: not', (tester) async {
    final bio = FakeBiometrics();
    await pump(tester, signedIn(), bio, lockEnabled: true);
    expect(home, findsOneWidget);
    bio.result = false;

    Future<void> background(Duration away) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      testNow = testNow.add(away);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    }

    await background(const Duration(seconds: 30));
    expect(lockScreen, findsNothing);

    await background(const Duration(minutes: 3));
    expect(lockScreen, findsOneWidget);
  });
}
