import 'package:flutter_mobile/core/design/state_views.dart';
import 'package:flutter_mobile/core/errors/app_failure.dart';
import 'package:flutter_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_mobile/features/auth/state/session.dart';
import 'package:flutter_mobile/features/demo/demo_mode.dart';
import 'package:flutter_mobile/features/times/domain/time_calc.dart';
import 'package:flutter_mobile/features/times/domain/time_rules.dart';
import 'package:flutter_mobile/features/times/model/records.dart';
import 'package:flutter_mobile/features/times/state/overview_provider.dart';
import 'package:flutter_mobile/features/times/times_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fake_overview_repository.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/pump_app.dart';

class _SampleOff extends DemoModeController {
  @override
  bool build() => false;
}

class _FixedSession extends SessionController {
  @override
  SessionState build() =>
      SignedIn(const AuthUser(id: 'u1', email: 'a@b.de'), userContext());
}

final today = DateTime.utc(2026, 11, 24);

Future<void> pumpTimes(WidgetTester tester, FakeOverviewRepository repo) async {
  await tester.pumpApp(
    TimesScreen(now: () => DateTime(2026, 11, 24, 12)),
    overrides: [
      sessionProvider.overrideWith(_FixedSession.new),
      demoModeProvider.overrideWith(_SampleOff.new),
      germanTodayProvider.overrideWithValue(today),
      overviewRepositoryProvider.overrideWithValue(repo),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the minutes the backend stored, for the whole month', (
    tester,
  ) async {
    final repo = FakeOverviewRepository(
      entries: [
        TimeRecord(
          id: 'e1',
          project: const ProjectRef('2025-003', 'Wartung'),
          activity: 'Montage',
          time: TimeEntry(
            start: DateTime.utc(2026, 11, 24, 7),
            end: DateTime.utc(2026, 11, 24, 11, 30),
          ),
          // Differs from the app's own 4:30 on purpose: stored wins.
          stored: const EntryTotals(
            total: 270,
            working: 255,
            night: 0,
            sunday: 0,
            holiday: 0,
          ),
        ),
      ],
    );
    await pumpTimes(tester, repo);
    expect(find.byKey(const Key('demoBadge')), findsNothing);
    expect(find.text('Wartung'), findsOneWidget);
    expect(find.text('4:15'), findsWidgets);
    // One load: November plus six days either side.
    expect(repo.loads, [
      (DateTime.utc(2026, 10, 26), DateTime.utc(2026, 12, 6)),
    ]);
  });

  testWidgets('a failed first load shows the error with retry', (tester) async {
    final repo = FakeOverviewRepository()..result = const NoConnection();
    await pumpTimes(tester, repo);
    expect(find.byType(ErrorView), findsOneWidget);

    repo.result = null;
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsNothing);
    expect(find.byKey(const Key('daySummary')), findsOneWidget);
    expect(find.byKey(const Key('missingDay')), findsOneWidget);
  });

  testWidgets('moving to another month loads that month', (tester) async {
    final repo = FakeOverviewRepository();
    await pumpTimes(tester, repo);
    await tester.tap(find.text('Monat'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left_rounded).first);
    await tester.pumpAndSettle();
    expect(repo.loads.last, (
      DateTime.utc(2026, 9, 25),
      DateTime.utc(2026, 11, 6),
    ));
  });
}
