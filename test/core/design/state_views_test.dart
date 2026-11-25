import 'package:flutter_mobile/core/design/app_theme.dart';
import 'package:flutter_mobile/core/design/state_views.dart';
import 'package:flutter_mobile/core/errors/app_failure.dart';
import 'package:flutter_mobile/core/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('ErrorView shows the German text and retries', (tester) async {
    var retried = 0;
    await tester.pumpApp(
      Scaffold(
        body: ErrorView(
          failure: const NoConnection(),
          onRetry: () => retried++,
        ),
      ),
    );
    expect(
      find.text('Keine Verbindung. Bitte Internetverbindung prüfen.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Erneut versuchen'));
    expect(retried, 1);
  });

  for (final theme in [AppTheme.light(), AppTheme.dark()]) {
    testWidgets('ErrorView meets accessibility guidelines '
        '(${theme.brightness.name})', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        Scaffold(
          body: ErrorView(failure: const UnknownFailure(), onRetry: () {}),
        ),
        theme: theme,
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }

  testWidgets('ErrorView survives 200 % font scaling', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpApp(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(
          body: ErrorView(failure: const ServerFailure('x'), onRetry: () {}),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  test('every failure has a German message', () {
    final l = lookupAppLocalizations(const Locale('de'));
    const failures = <AppFailure>[
      NoConnection(),
      InvalidCredentials(),
      AccountDisabled(),
      SessionExpired(),
      AccessDenied(),
      ServerFailure(null),
      UnknownFailure(),
    ];
    final texts = failures.map((f) => f.message(l)).toSet();
    expect(texts, hasLength(failures.length));
    expect(
      const InvalidCredentials().message(l),
      'E-Mail oder Passwort falsch',
    );
  });
}
