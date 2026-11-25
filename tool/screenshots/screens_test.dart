// Renders the main screens to PNGs for a visual check, light and dark.
// Not part of the test suite. Run:
//   flutter test tool/screenshots --update-goldens
// Output: tool/screenshots/out/*.png (git-ignored).
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_mobile/core/errors/app_failure.dart';
import 'package:flutter_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../test/helpers/fake_auth_repository.dart';
import '../../test/helpers/test_app.dart';

Future<void> _loadFonts() async {
  final inter = FontLoader('Inter');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/inter/Inter-$w.ttf').readAsBytesSync();
    inter.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await inter.load();
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ?? 'C:/Users/ihebl/flutter';
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(
        ByteData.view(
          File(
            '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytesSync().buffer,
        ),
      ),
    );
  await icons.load();
}

void main() {
  setUpAll(_loadFonts);

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    Future<void> shoot(WidgetTester tester, String name) async {
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp).first,
        matchesGoldenFile('out/${name}_$mode.png'),
      );
    }

    void useMode(WidgetTester tester) {
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    }

    testWidgets('sign-in $mode', (tester) async {
      useMode(tester);
      await pumpFullApp(tester, FakeAuthRepository());
      await shoot(tester, '1_sign_in');
      await tester.tap(find.text('Anmelden'));
      await shoot(tester, '2_sign_in_errors');
    });

    testWidgets('sign-in with saved sign-in $mode', (tester) async {
      useMode(tester);
      final auth = FakeAuthRepository();
      await pumpFullApp(
        tester,
        auth,
        null,
        const [Locale('de', 'DE')],
        .system,
        null,
        FakeBiometrics(),
      );
      await tester.enterText(find.byKey(const Key('email')), 'anna@firma.de');
      await tester.enterText(find.byKey(const Key('password')), auth.password);
      await tester.tap(find.text('Anmelden'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aktivieren'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Mehr'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('signOut')));
      await shoot(tester, '1b_sign_in_quick');
    });

    testWidgets('forgot password $mode', (tester) async {
      useMode(tester);
      await pumpFullApp(tester, FakeAuthRepository());
      await tester.tap(find.text('Passwort vergessen?'));
      await shoot(tester, '8_reset');
      await tester.enterText(find.byType(TextFormField), 'anna@firma.de');
      await tester.tap(find.text('Link senden'));
      await shoot(tester, '9_reset_sent');
    });

    testWidgets('home $mode', (tester) async {
      useMode(tester);
      await pumpFullApp(
        tester,
        FakeAuthRepository(
          user: const AuthUser(id: 'u1', email: 'anna@firma.de'),
        ),
      );
      await shoot(tester, '3_times');
      await tester.tap(find.text('Woche'));
      await shoot(tester, '3b_week');
      await tester.tap(find.text('Monat'));
      await shoot(tester, '3c_month');
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -500),
      );
      await tester.tap(find.text('Tag'));
      await shoot(tester, '3d_day_scrolled');
      await tester.tap(find.bySemanticsLabel('Protokoll'));
      await shoot(tester, '4_history');
      await tester.tap(find.bySemanticsLabel('Abwesenheit'));
      await shoot(tester, '4b_absence');
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await shoot(tester, '4c_absence_scrolled');
      await tester.tap(find.bySemanticsLabel('Mehr'));
      await shoot(tester, '5_more');
      await tester.tap(find.byKey(const Key('bell')).first);
      await shoot(tester, '4d_notifications');
    });

    testWidgets('entry form $mode', (tester) async {
      useMode(tester);
      await pumpFullApp(
        tester,
        FakeAuthRepository(
          user: const AuthUser(id: 'u1', email: 'anna@firma.de'),
        ),
      );
      await tester.tap(find.byTooltip('Neuer Eintrag'));
      await shoot(tester, '6_entry_new');
      await tester.tap(find.byKey(const Key('project')));
      await tester.pumpAndSettle();
      await shoot(tester, '6b_entry_projects');
      await tester.tap(find.text('Neubau Kita Sonnenschein'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await shoot(tester, '6c_entry_scrolled');
      await tester.tap(find.byKey(const Key('saveEntry')));
      await shoot(tester, '6d_entry_not_saved');
    });

    testWidgets('lock $mode', (tester) async {
      useMode(tester);
      await pumpFullApp(
        tester,
        FakeAuthRepository(
          user: const AuthUser(id: 'u1', email: 'a@b.de'),
        ),
        null,
        const [Locale('de', 'DE')],
        .system,
        null,
        FakeBiometrics(result: false),
        true,
      );
      await shoot(tester, '6_lock');
    });

    testWidgets('offline $mode', (tester) async {
      useMode(tester);
      final contexts = FakeContextRepository()..result = const NoConnection();
      await pumpFullApp(
        tester,
        FakeAuthRepository(
          user: const AuthUser(id: 'u1', email: 'a@b.de'),
        ),
        contexts,
        const [Locale('de', 'DE')],
        .system,
        FakeNetworkStatus(false),
      );
      await shoot(tester, '7_offline');
    });
  }
}
