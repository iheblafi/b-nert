import 'package:flutter_mobile/core/errors/app_failure.dart';
import 'package:flutter_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fixtures.dart';
import '../helpers/test_app.dart';

void main() {
  Future<void> signIn(WidgetTester tester, String password) async {
    await tester.enterText(find.byKey(const Key('email')), ' anna@firma.de ');
    await tester.enterText(find.byKey(const Key('password')), password);
    await tester.tap(find.text('Anmelden'));
    await tester.pumpAndSettle();
  }

  testWidgets('sprint goal: sign in leads to the empty home screen', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await pumpFullApp(tester, auth);
    expect(find.text('Passwort vergessen?'), findsOneWidget);

    await signIn(tester, auth.password);

    // Shell (b7): four destinations, central button, bell.
    for (final label in ['Zeiten', 'Protokoll', 'Abwesenheit', 'Mehr']) {
      expect(find.bySemanticsLabel(label), findsWidgets);
    }
    expect(find.byKey(const Key('newEntry')), findsOneWidget);
    expect(find.byKey(const Key('bell')), findsOneWidget);
    expect(auth.user?.email, 'anna@firma.de');
    // Personal header on Zeiten.
    expect(find.textContaining('Anna'), findsOneWidget);
  });

  testWidgets('empty fields are validated before any request', (tester) async {
    final auth = FakeAuthRepository();
    await pumpFullApp(tester, auth);
    await tester.tap(find.text('Anmelden'));
    await tester.pump();
    expect(find.text('Bitte E-Mail eingeben'), findsOneWidget);
    expect(find.text('Bitte Passwort eingeben'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('email')), 'kein-at');
    await tester.tap(find.text('Anmelden'));
    await tester.pump();
    expect(find.text('Bitte eine gültige E-Mail eingeben'), findsOneWidget);
  });

  testWidgets('wrong credentials: neutral message (AC2)', (tester) async {
    final auth = FakeAuthRepository();
    await pumpFullApp(tester, auth);
    await signIn(tester, 'falsch');
    expect(find.text('E-Mail oder Passwort falsch'), findsOneWidget);
    expect(find.byKey(const Key('newEntry')), findsNothing);
  });

  testWidgets('password can be shown and hidden', (tester) async {
    await pumpFullApp(tester, FakeAuthRepository());
    expect(find.byTooltip('Passwort anzeigen'), findsOneWidget);
    await tester.tap(find.byTooltip('Passwort anzeigen'));
    await tester.pump();
    expect(find.byTooltip('Passwort verbergen'), findsOneWidget);
  });

  testWidgets('navigation between the four destinations', (tester) async {
    final auth = FakeAuthRepository(
      user: const AuthUser(id: 'u1', email: 'a@b.de'),
    );
    await pumpFullApp(tester, auth);
    await tester.tap(find.bySemanticsLabel('Protokoll'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Protokoll'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Mehr'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('signOut')), findsOneWidget);

    await tester.tap(find.byKey(const Key('newEntry')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Neuer Eintrag'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bell')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Benachrichtigungen'), findsOneWidget);
  });

  testWidgets('approvals entry only for users who may approve', (tester) async {
    final auth = FakeAuthRepository(
      user: const AuthUser(id: 'u1', email: 'a@b.de'),
    );
    await pumpFullApp(tester, auth);
    await tester.tap(find.bySemanticsLabel('Mehr'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('approvals')), findsNothing);
  });

  testWidgets('supervisor sees the approvals entry', (tester) async {
    final auth = FakeAuthRepository(
      user: const AuthUser(id: 'u1', email: 'a@b.de'),
    );
    await pumpFullApp(
      tester,
      auth,
      FakeContextRepository(userContext(supervises: true)),
    );
    await tester.tap(find.bySemanticsLabel('Mehr'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('approvals')), findsOneWidget);
  });

  testWidgets('sign out returns to the sign-in screen (AC10)', (tester) async {
    final auth = FakeAuthRepository(
      user: const AuthUser(id: 'u1', email: 'a@b.de'),
    );
    await pumpFullApp(tester, auth);
    await tester.tap(find.bySemanticsLabel('Mehr'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signOut')));
    await tester.pumpAndSettle();
    expect(find.text('Anmelden'), findsOneWidget);
    expect(auth.user, isNull);
  });

  testWidgets('no licence: Kein Zugriff with sign out (AC3)', (tester) async {
    final auth = FakeAuthRepository(
      user: const AuthUser(id: 'u1', email: 'a@b.de'),
    );
    await pumpFullApp(
      tester,
      auth,
      FakeContextRepository(userContext(licence: false)),
    );
    expect(find.text('Kein Zugriff'), findsOneWidget);
    await tester.tap(find.text('Abmelden'));
    await tester.pumpAndSettle();
    expect(find.text('Anmelden'), findsOneWidget);
  });

  testWidgets('disabled account is told why after refresh fails (AC4)', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      user: const AuthUser(id: 'u1', email: 'a@b.de'),
    );
    await pumpFullApp(tester, auth);
    auth.emit(const SignedOutEvent(AccountDisabled()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('signInError')), findsOneWidget);
    expect(find.textContaining('deaktiviert'), findsOneWidget);
  });

  testWidgets('context load fails: error with retry', (tester) async {
    final auth = FakeAuthRepository(
      user: const AuthUser(id: 'u1', email: 'a@b.de'),
    );
    final contexts = FakeContextRepository()..result = const NoConnection();
    await pumpFullApp(tester, auth, contexts);
    expect(find.text('Erneut versuchen'), findsOneWidget);
    contexts.result = userContext();
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('newEntry')), findsOneWidget);
  });
}
