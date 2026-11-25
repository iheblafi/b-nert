import 'package:flutter_mobile/features/time_entry/model/entry_draft.dart';
import 'package:flutter_mobile/features/times/domain/time_rules.dart';
import 'package:flutter_mobile/features/times/model/overview_data.dart';
import 'package:flutter_mobile/features/times/model/records.dart';
import 'package:flutter_mobile/features/user_context/model/company_settings.dart';
import 'package:flutter_test/flutter_test.dart';

final monday = DateTime.utc(2026, 11, 23);
final now = DateTime.utc(2026, 11, 24, 9);

// Stage settings (docs/research/web-calculation-rules.md).
const stage = CompanySettings(
  minBreakPieceMinutes: 15,
  minRestHours: 11,
  maxDelayHours: 180,
);

EntryDraft draft({
  DateTime? day,
  ClockTime start = (hour: 8, minute: 0),
  ClockTime end = (hour: 16, minute: 30),
  int brk = 30,
  String? project = 'p1',
  int? night,
  String? id,
}) => EntryDraft(
  id: id,
  projectId: project,
  day: day ?? monday,
  start: start,
  end: end,
  breakMinutes: brk,
  night: night,
);

TimeRecord other(
  DateTime start,
  DateTime end, {
  int brk = 0,
  String id = 'o',
}) => TimeRecord(
  id: id,
  project: const ProjectRef('1', 'P'),
  activity: '',
  time: TimeEntry(id: id, start: start, end: end, breakMinutes: brk),
);

OverviewData overview({
  List<TimeRecord> entries = const [],
  List<AbsenceRecord> absences = const [],
  Map<DateTime, String> holidays = const {},
}) => OverviewData(
  today: DateTime.utc(2026, 11, 24),
  rules: stage.timeRules,
  entries: entries,
  holidays: holidays,
  absences: absences,
);

EntryCheck check(
  EntryDraft d, {
  CompanySettings settings = stage,
  OverviewData? o,
  bool locked = false,
  DateTime? at,
}) => checkDraft(
  d,
  settings: settings,
  now: at ?? now,
  overview: o ?? overview(),
  locked: locked,
);

void main() {
  test('a normal day passes with no warnings', () {
    final c = check(draft());
    expect(c.errors, isEmpty);
    expect(c.warnings, isEmpty);
    expect(c.totals.total, 510);
    expect(c.totals.working, 480);
    expect(c.canSave, isTrue);
  });

  test('no project blocks saving (AC1)', () {
    expect(check(draft(project: null)).errors, {
      EntryField.project: EntryError.noProject,
    });
  });

  test('an end at the start is not after it (AC1)', () {
    final c = check(draft(end: (hour: 8, minute: 0)));
    expect(c.errors[EntryField.end], EntryError.endNotAfterStart);
  });

  test('an end before the start is the next day: a night shift', () {
    final d = draft(
      start: (hour: 22, minute: 0),
      end: (hour: 6, minute: 0),
      brk: 30,
    );
    expect(d.endsNextDay, isTrue);
    expect(d.endAt, DateTime.utc(2026, 11, 24, 6));
    final c = check(d);
    expect(c.errors, isEmpty);
    expect(c.totals.total, 480);
    expect(c.totals.night, 450);
  });

  test('break longer than the entry (AC1)', () {
    final c = check(draft(end: (hour: 8, minute: 20), brk: 30));
    expect(c.errors[EntryField.breakMinutes], EntryError.breakLongerThanEntry);
  });

  test('surcharge typed above the working time (AC1)', () {
    final c = check(draft(night: 600));
    expect(c.errors[EntryField.night], EntryError.surchargeAboveWorking);
    expect(c.totals.night, 600);
  });

  test('hidden surcharges count as zero', () {
    final c = check(
      draft(start: (hour: 22, minute: 0), end: (hour: 6, minute: 0)),
      settings: const CompanySettings(showSurchargeTimes: false),
    );
    expect(c.totals.night, 0);
  });

  test('overlap with another entry is refused (AC2)', () {
    final o = overview(
      entries: [
        other(
          DateTime.utc(2026, 11, 23, 16),
          DateTime.utc(2026, 11, 23, 18),
          id: 'x',
        ),
      ],
    );
    expect(check(draft(), o: o).errors[EntryField.end], EntryError.overlap);
    // Touching is fine.
    expect(check(draft(end: (hour: 16, minute: 0)), o: o).errors, isEmpty);
    // Editing the same entry does not overlap itself.
    expect(check(draft(id: 'x'), o: o).errors, isEmpty);
  });

  test('too little break is a warning, with the suggestion (AC3)', () {
    final c = check(draft(end: (hour: 17, minute: 0), brk: 0));
    expect(c.canSave, isTrue);
    expect(c.warnings.whereType<BreakTooShort>().single.required, 30);
    expect(c.suggestedBreak, 30);
  });

  test('break across two entries counts the gap', () {
    final o = overview(
      entries: [
        other(DateTime.utc(2026, 11, 23, 7), DateTime.utc(2026, 11, 23, 11)),
      ],
    );
    final c = check(draft(start: (hour: 11, minute: 30), brk: 0), o: o);
    expect(c.warnings.whereType<BreakTooShort>(), isEmpty);
    expect(c.suggestedBreak, 0);
    // An entry two days earlier does not change the suggestion.
    final far = overview(
      entries: [
        other(DateTime.utc(2026, 11, 21, 7), DateTime.utc(2026, 11, 21, 18)),
      ],
    );
    final c2 = check(draft(brk: 0), o: far);
    expect(c2.suggestedBreak, 30);
    // Only this shift's break is asked for, not the other day's too.
    expect(c2.warnings.whereType<BreakTooShort>().single.required, 30);
  });

  // Longest free stretch in the 24 h before the start: 23:00 to 06:00.
  test('rest time below 11 hours is a warning', () {
    final o = overview(
      entries: [
        other(DateTime.utc(2026, 11, 22, 8), DateTime.utc(2026, 11, 22, 23)),
      ],
    );
    final c = check(
      draft(start: (hour: 6, minute: 0), end: (hour: 10, minute: 0), brk: 0),
      o: o,
    );
    final rest = c.warnings.whereType<RestTooShort>().single;
    expect(rest.rest, 7 * 60);
    expect(rest.required, 11 * 60);
  });

  test('entry on an absence day follows the company setting (AC4)', () {
    final o = overview(
      absences: [
        AbsenceRecord(
          type: AbsenceType.vacation,
          from: monday,
          to: monday,
          days: 1,
          status: RequestStatus.approved,
        ),
      ],
    );
    expect(
      check(draft(), o: o).warnings.whereType<OnAbsenceDay>(),
      hasLength(1),
    );
    expect(
      check(
        draft(),
        o: o,
        settings: const CompanySettings(
          entryDuringAbsence: EntryDuringAbsence.block,
        ),
      ).errors[EntryField.date],
      EntryError.absenceBlocks,
    );
    expect(
      check(
        draft(),
        o: o,
        settings: const CompanySettings(
          entryDuringAbsence: EntryDuringAbsence.allow,
        ),
      ).warnings,
      isEmpty,
    );
  });

  test('late entry needs approval (AC5)', () {
    final old = draft(day: DateTime.utc(2026, 11, 10));
    expect(check(old).warnings.whereType<NeedsApproval>(), hasLength(1));
    expect(check(draft()).warnings.whereType<NeedsApproval>(), isEmpty);
  });

  test('a locked entry cannot be saved (AC6)', () {
    expect(
      check(draft(), locked: true).errors[EntryField.date],
      EntryError.locked,
    );
  });

  test('holiday minutes come from the user holidays or the chosen state', () {
    final day = DateTime.utc(2026, 11, 18); // Buß- und Bettag, Saxony only
    final o = overview(holidays: {day: 'Buß- und Bettag'});
    expect(check(draft(day: day), o: o).totals.holiday, greaterThan(0));
    final inBavaria = draft(day: day).copyWith(holidayState: () => 'BY');
    expect(check(inBavaria, o: o).totals.holiday, 0);
  });

  test('without loaded entries the form says it could not compare', () {
    final c = checkDraft(draft(), settings: stage, now: now);
    expect(c.comparedWithOthers, isFalse);
    expect(c.errors, isEmpty);
  });

  test('more than 24 hours is impossible: the end wraps to the next day', () {
    final d = draft(start: (hour: 8, minute: 0), end: (hour: 7, minute: 55));
    expect(check(d).totals.total, 23 * 60 + 55);
  });
}
