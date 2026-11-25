import 'package:flutter_mobile/core/l10n/language.dart';
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

  Future<void> pick(WidgetTester tester, AppLanguage language) async {
    await tester.tap(find.byKey(Key('language-${language.name}')));
    await tester.pumpAndSettle();
  }

  group('resolveLocale', () {
    test('uses the first supported device language', () {
      expect(resolveLocale(const [Locale('en', 'US')]), const Locale('en'));
      expect(
        resolveLocale(const [Locale('fr'), Locale('de', 'AT')]),
        const Locale('de'),
      );
    });

    test('falls back to German', () {
      expect(resolveLocale(const [Locale('tr', 'TR')]), const Locale('de'));
      expect(resolveLocale(null), const Locale('de'));
    });
  });

  testWidgets('follows an English device', (tester) async {
    await pumpFullApp(tester, FakeAuthRepository(), null, const [
      Locale('en', 'GB'),
    ]);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('a device in another language gets German', (tester) async {
    await pumpFullApp(tester, FakeAuthRepository(), null, const [
      Locale('tr', 'TR'),
    ]);
    expect(find.text('Anmelden'), findsOneWidget);
  });

  testWidgets('language can be changed on the sign-in screen and is kept', (
    tester,
  ) async {
    await pumpFullApp(tester, FakeAuthRepository());
    await tester.tap(find.byKey(const Key('languageButton')));
    await tester.pumpAndSettle();
    await pick(tester, AppLanguage.en);

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(await SharedPreferencesAsync().getString(LanguageStore.key), 'en');
  });

  testWidgets('language can be changed under More', (tester) async {
    await pumpFullApp(tester, signedIn());
    await tester.tap(find.bySemanticsLabel('Mehr'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language')));
    await tester.pumpAndSettle();
    await pick(tester, AppLanguage.en);

    for (final label in ['Times', 'History', 'Absence', 'More']) {
      expect(find.bySemanticsLabel(label), findsWidgets);
    }
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('a forced language wins over the device, device language '
      'returns it', (tester) async {
    await pumpFullApp(tester, signedIn(), null, const [
      Locale('en', 'US'),
    ], AppLanguage.de);
    await tester.tap(find.bySemanticsLabel('Mehr'));
    await tester.pumpAndSettle();
    expect(find.text('Deutsch'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language')));
    await tester.pumpAndSettle();
    await pick(tester, AppLanguage.system);
    expect(find.text('Device language'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });
}
