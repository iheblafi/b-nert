import 'package:flutter_mobile/features/times/domain/expected_time.dart';
import 'package:flutter_mobile/features/times/domain/time_calc.dart';
import 'package:flutter_mobile/features/times/domain/time_rules.dart';
import 'package:flutter_mobile/features/times/model/overview_data.dart';
import 'package:flutter_mobile/features/times/model/records.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int m, int day) => DateTime.utc(2026, m, day);

TimeRecord entry(
  DateTime day,
  int fromH,
  int toH, {
  int brk = 0,
  int? stored,
}) => TimeRecord(
  id: '$day$fromH',
  project: const ProjectRef('1', 'P'),
  activity: '',
  time: TimeEntry(
    start: day.add(Duration(hours: fromH)),
    end: day.add(Duration(hours: toH)),
    breakMinutes: brk,
  ),
  stored: stored == null
      ? null
      : EntryTotals(
          total: stored,
          working: stored,
          night: 0,
          sunday: 0,
          holiday: 0,
        ),
);

OverviewData data({
  List<TimeRecord> entries = const [],
  Map<DateTime, String> holidays = const {},
  Set<DateTime> half = const {},
  List<AbsenceRecord> absences = const [],
  ExpectedTime expected = ExpectedTime.fallback,
}) => OverviewData(
  today: d(11, 24),
  rules: const TimeRules(minBreakPieceMinutes: 15),
  entries: entries,
  holidays: holidays,
  halfDayHolidays: half,
  absences: absences,
  expected: expected,
);

void main() {
  test('fallback model: 8 h Monday to Friday', () {
    final o = data();
    expect(o.expectedOn(d(11, 23)), 480); // Monday
    expect(o.expectedOn(d(11, 22)), 0); // Sunday
    expect(o.statusOf(d(11, 22)), DayStatus.weekend);
    expect(o.statusOf(d(11, 23)), DayStatus.missing);
    expect(o.statusOf(d(11, 25)), DayStatus.future);
  });

  test('work time model with periods and a free Friday', () {
    final model = ExpectedTime([
      WorkTimeModelPeriod(
        from: d(11, 1),
        minutesByWeekday: const [450, 450, 450, 450, 0, 0, 0],
      ),
      WorkTimeModelPeriod(
        from: d(1, 1),
        to: d(10, 31),
        minutesByWeekday: const [480, 480, 480, 480, 480, 0, 0],
      ),
    ]);
    final o = data(expected: model);
    expect(o.expectedOn(d(11, 23)), 450);
    expect(o.expectedOn(d(11, 20)), 0); // Friday off in the new model
    expect(o.statusOf(d(11, 20)), DayStatus.weekend);
    expect(o.expectedOn(d(10, 30)), 480); // old model
  });

  test('holidays and absences reduce the target; half days halve it', () {
    final o = data(
      holidays: {d(11, 18): 'Buß- und Bettag', d(12, 24): 'Heiligabend'},
      half: {d(12, 24)},
      absences: [
        AbsenceRecord(
          type: AbsenceType.vacation,
          from: d(11, 9),
          to: d(11, 13),
          days: 4.5,
          status: RequestStatus.approved,
          lastDayMorningOnly: true,
        ),
        AbsenceRecord(
          type: AbsenceType.vacation,
          from: d(11, 16),
          to: d(11, 16),
          days: 1,
          status: RequestStatus.pending,
        ),
      ],
    );
    expect(o.expectedOn(d(11, 18)), 0);
    expect(o.statusOf(d(11, 18)), DayStatus.holiday);
    expect(o.expectedOn(d(12, 24)), 240);
    expect(o.expectedOn(d(11, 10)), 0);
    expect(o.statusOf(d(11, 10)), DayStatus.absent);
    expect(o.expectedOn(d(11, 13)), 240); // morning off only
    expect(o.statusOf(d(11, 13)), DayStatus.missing);
    expect(o.expectedOn(d(11, 16)), 480); // pending does not count
  });

  test(
    'stored minutes win over the calculation; late entries do not count',
    () {
      final late = TimeRecord(
        id: 'late',
        project: const ProjectRef('1', 'P'),
        activity: '',
        time: TimeEntry(
          start: d(11, 23).add(const Duration(hours: 13)),
          end: d(11, 23).add(const Duration(hours: 15)),
        ),
        delay: DelayStatus.pending,
      );
      final o = data(entries: [entry(d(11, 23), 8, 12, stored: 230), late]);
      expect(o.workedOn(d(11, 23)), 230);
      expect(o.statusOf(d(11, 23)), DayStatus.incomplete);
    },
  );
}
