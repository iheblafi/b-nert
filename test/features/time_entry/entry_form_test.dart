import 'package:flutter_mobile/core/design/state_views.dart';
import 'package:flutter_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_mobile/features/auth/state/session.dart';
import 'package:flutter_mobile/features/demo/demo_mode.dart';
import 'package:flutter_mobile/features/time_entry/data/entry_options_repository.dart';
import 'package:flutter_mobile/features/time_entry/ui/entry_form_screen.dart';
import 'package:flutter_mobile/features/times/domain/time_calc.dart';
import 'package:flutter_mobile/features/times/domain/time_rules.dart';
import 'package:flutter_mobile/features/times/model/records.dart';
import 'package:flutter_mobile/features/times/state/overview_provider.dart';
import 'package:flutter_mobile/features/user_context/model/company_settings.dart';
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
  _FixedSession(this.fixed);
  final SessionState fixed;

  @override
  SessionState build() => fixed;
}

Future<FakeOverviewRepository> pumpForm(
  WidgetTester tester, {
  CompanySettings settings = const CompanySettings(
    workPlaceMode: WorkPlaceMode.record,
    showHolidayState: true,
  ),
  TimeRecord? entry,
  DateTime? day,
  FakeOverviewRepository? overview,
}) async {
  final repo = overview ?? FakeOverviewRepository();
  await tester.pumpApp(
    EntryFormScreen(entry: entry, day: day ?? DateTime.utc(2026, 11, 23)),
    overrides: [
      sessionProvider.overrideWith(
        () => _FixedSession(
          SignedIn(
            const AuthUser(id: 'u1', email: 'a@b.de'),
            userContext(settings: settings),
          ),
        ),
      ),
      demoModeProvider.overrideWith(_SampleOff.new),
      germanTodayProvider.overrideWithValue(DateTime.utc(2026, 11, 24)),
      overviewRepositoryProvider.overrideWithValue(repo),
      entryOptionsRepositoryProvider.overrideWithValue(
        FakeEntryOptionsRepository(),
      ),
    ],
  );
  await tester.pumpAndSettle();
  final error = find.byType(ErrorView);
  if (error.evaluate().isNotEmpty) {
    fail('Form failed to load: ${tester.widget<ErrorView>(error).failure}');
  }
  return repo;
}

/// The form's own list, not a dropdown or segmented button inside it.
final formList = find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

Future<void> chooseProject(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('project')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('saveEntry')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('defaults from company settings; saving is off and says so', (
    tester,
  ) async {
    await pumpForm(tester);
    expect(find.byKey(const Key('savingOff')), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('16:30'), findsOneWidget);
    // 8.5 h with no break yet: the web's suggestion is 30 min.
    expect(find.byKey(const Key('suggestedBreak')), findsOneWidget);
  });

  testWidgets('no project: saving names the field (AC1)', (tester) async {
    await pumpForm(tester);
    await save(tester);
    expect(find.text('Bitte ein Projekt wählen'), findsOneWidget);
    expect(find.byKey(const Key('notSavedDialog')), findsNothing);
  });

  testWidgets('complete form: nothing is sent, the dialog says so', (
    tester,
  ) async {
    await pumpForm(tester);
    await chooseProject(tester, 'Rathaus');
    // Sub-project appears once a project with sub-projects is chosen.
    expect(find.byKey(const Key('subproject')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('suggestedBreak')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('suggestedBreak')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('breakValue'))).data,
      '30 Min',
    );
    // The suggestion is used: no chip, no break warning.
    expect(find.byKey(const Key('suggestedBreak')), findsNothing);
    // The button sits below the list, always visible.
    await save(tester);
    expect(find.byKey(const Key('notSavedDialog')), findsOneWidget);
    expect(find.textContaining('nichts gespeichert'), findsOneWidget);
  });

  testWidgets('too little break is a warning, not a block (AC3)', (
    tester,
  ) async {
    await pumpForm(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('entryWarnings')),
      200,
      scrollable: formList,
    );
    expect(find.byKey(const Key('entryWarnings')), findsOneWidget);
    expect(
      find.textContaining('30 Minuten sind vorgeschrieben'),
      findsOneWidget,
    );
  });

  testWidgets('overlap with a loaded entry is refused (AC2)', (tester) async {
    final repo = FakeOverviewRepository(
      entries: [
        TimeRecord(
          id: 'x',
          project: const ProjectRef('1', 'P'),
          activity: '',
          time: TimeEntry(
            id: 'x',
            start: DateTime.utc(2026, 11, 23, 15),
            end: DateTime.utc(2026, 11, 23, 18),
          ),
        ),
      ],
    );
    await pumpForm(tester, overview: repo);
    expect(
      find.text('Eintrag überlappt mit anderen Einträgen'),
      findsOneWidget,
    );
  });

  testWidgets('fields follow the company settings', (tester) async {
    await pumpForm(
      tester,
      settings: const CompanySettings(
        showActivity: false,
        showSurchargeTimes: false,
        furtherDetails: FurtherDetailsMode.hidden,
      ),
    );
    expect(find.byKey(const Key('activity')), findsNothing);
    expect(find.byKey(const Key('surcharge-night')), findsNothing);
    expect(find.byKey(const Key('remarks')), findsNothing);
    expect(find.byKey(const Key('workPlace')), findsNothing);
  });

  testWidgets('collapsed further details open on tap', (tester) async {
    await pumpForm(
      tester,
      settings: const CompanySettings(
        furtherDetails: FurtherDetailsMode.collapsed,
        workPlaceMode: WorkPlaceMode.record,
      ),
    );
    expect(find.byKey(const Key('remarks')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('furtherDetails')),
      200,
      scrollable: formList,
    );
    await tester.tap(find.byKey(const Key('furtherDetails')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('remarks')), findsOneWidget);
    expect(find.byKey(const Key('workPlace')), findsOneWidget);
  });

  testWidgets('a closed entry is read-only with the reason (AC6)', (
    tester,
  ) async {
    await pumpForm(
      tester,
      entry: TimeRecord(
        id: 'c',
        project: const ProjectRef('2025-001', 'Rathaus', id: 'p1'),
        activity: 'Montage',
        time: TimeEntry(
          id: 'c',
          start: DateTime.utc(2026, 10, 1, 7),
          end: DateTime.utc(2026, 10, 1, 15),
          breakMinutes: 30,
        ),
        status: EntryStatus.closed,
        stored: const EntryTotals(
          total: 480,
          working: 450,
          night: 0,
          sunday: 0,
          holiday: 0,
        ),
      ),
    );
    expect(find.text('Eintrag bearbeiten'), findsOneWidget);
    expect(find.textContaining('festgeschrieben'), findsWidgets);
    expect(find.text('2025-001 · Rathaus'), findsOneWidget);
    final button = tester.widget<ButtonStyleButton>(
      find.byKey(const Key('saveEntry')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('a night shift ends the next day', (tester) async {
    await pumpForm(
      tester,
      entry: TimeRecord(
        id: 'n',
        project: const ProjectRef('2025-002', 'Kita', id: 'p2'),
        activity: '',
        time: TimeEntry(
          id: 'n',
          start: DateTime.utc(2026, 11, 19, 22),
          end: DateTime.utc(2026, 11, 20, 6),
          breakMinutes: 30,
        ),
      ),
    );
    expect(find.text('Ende (nächster Tag)'), findsOneWidget);
    expect(find.text('7:30'), findsWidgets);
  });
}
