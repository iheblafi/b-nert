import 'package:flutter_mobile/core/l10n/language.dart';
import 'package:flutter_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('turning the lock on fails visibly when the prompt fails', (
    tester,
  ) async {
    final bio = FakeBiometrics(result: false);
    await pumpFullApp(
      tester,
      FakeAuthRepository(
        user: const AuthUser(id: 'u1', email: 'a@b.de'),
      ),
      null,
      const [Locale('de', 'DE')],
      AppLanguage.system,
      null,
      bio,
    );
    await tester.tap(find.bySemanticsLabel('Mehr'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appLockSwitch')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Entsperren mit Displaysperre konnte nicht eingerichtet werden.',
      ),
      findsOneWidget,
    );
    final tile = tester.widget<SwitchListTile>(
      find.byKey(const Key('appLockSwitch')),
    );
    expect(tile.value, isFalse);
  });
}
