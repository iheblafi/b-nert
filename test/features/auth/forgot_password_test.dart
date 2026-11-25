import 'package:flutter_mobile/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/test_app.dart';

void main() {
  const neutral =
      'Wenn ein Konto zu dieser E-Mail existiert, haben wir dir einen Link '
      'geschickt. Bitte prüfe dein Postfach.';

  Future<void> openAndSend(WidgetTester tester, FakeAuthRepository auth) async {
    await pumpFullApp(tester, auth);
    await tester.tap(find.text('Passwort vergessen?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'anna@firma.de');
    await tester.tap(find.text('Link senden'));
    await tester.pumpAndSettle();
  }

  testWidgets('sends the request and shows the neutral answer (AC7)', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await openAndSend(tester, auth);
    expect(auth.resetRequests, ['anna@firma.de']);
    expect(find.text(neutral), findsOneWidget);

    await tester.tap(find.text('Zurück zur Anmeldung'));
    await tester.pumpAndSettle();
    expect(find.text('Anmelden'), findsOneWidget);
  });

  testWidgets('no connection is reported, not hidden', (tester) async {
    final auth = FakeAuthRepository(resetError: const NoConnection());
    await openAndSend(tester, auth);
    expect(find.text(neutral), findsNothing);
    expect(find.textContaining('Keine Verbindung'), findsOneWidget);
  });

  testWidgets('invalid e-mail is not sent', (tester) async {
    final auth = FakeAuthRepository();
    await pumpFullApp(tester, auth);
    await tester.tap(find.text('Passwort vergessen?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'anna');
    await tester.tap(find.text('Link senden'));
    await tester.pumpAndSettle();
    expect(auth.resetRequests, isEmpty);
  });
}
