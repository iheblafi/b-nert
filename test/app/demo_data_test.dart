import 'package:flutter_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/test_app.dart';

void main() {
  Future<void> open(WidgetTester tester) => pumpFullApp(
    tester,
    FakeAuthRepository(
      user: const AuthUser(id: 'u1', email: 'a@b.de'),
    ),
  );

  testWidgets('sample data: Zeiten shows day, week and month', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('demoBadge')), findsWidgets);
    expect(find.byKey(const Key('daySummary')), findsOneWidget);

    await tester.tap(find.text('Woche'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weekTotal')), findsOneWidget);

    await tester.tap(find.text('Monat'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('monthTotal')), findsOneWidget);
  });

  testWidgets('sample data: history filters change the list', (tester) async {
    await open(tester);
    await tester.tap(find.bySemanticsLabel('Protokoll'));
    await tester.pumpAndSettle();
    String count() =>
        tester.widget<Text>(find.byKey(const Key('historyCount'))).data!;
    final all = count();

    await tester.ensureVisible(find.byKey(const Key('filter-notCounted')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-notCounted')));
    await tester.pumpAndSettle();
    expect(count(), isNot(all));
    expect(count(), startsWith('2 '));
  });

  testWidgets('sample data: absence shows balance, requests and team', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.bySemanticsLabel('Abwesenheit'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('leaveCard')), findsOneWidget);
    expect(find.text('Meine Anträge'.toUpperCase()), findsOneWidget);
  });

  testWidgets('switching sample data off shows the real overview', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.bySemanticsLabel('Mehr'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('demoSwitch')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('demoSwitch')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Zeiten'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('demoBadge')), findsNothing);
    expect(find.byKey(const Key('daySummary')), findsOneWidget);
    // No entries on stage for today: the missing-day card and the note
    // that Soll is calculated in the app.
    expect(find.byKey(const Key('missingDay')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('targetNote')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('targetNote')), findsOneWidget);
    expect(testOverview.loads, isNotEmpty);
  });
}
