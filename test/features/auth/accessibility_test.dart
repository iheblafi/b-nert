import 'package:flutter_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/test_app.dart';

void main() {
  Future<void> checkGuidelines(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  testWidgets('sign-in screen meets guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpFullApp(tester, FakeAuthRepository());
    await checkGuidelines(tester);
    handle.dispose();
  });

  testWidgets('home shell meets guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpFullApp(
      tester,
      FakeAuthRepository(
        user: const AuthUser(id: 'u1', email: 'a@b.de'),
      ),
    );
    await checkGuidelines(tester);
    handle.dispose();
  });

  testWidgets('sign-in screen at 200 % font size has no overflow', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpFullApp(tester, FakeAuthRepository());
    expect(tester.takeException(), isNull);
  });
}
