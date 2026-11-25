import 'package:flutter_mobile/features/times/domain/time_calc.dart';
import 'package:flutter_mobile/features/times/domain/time_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// German wall-clock time.
DateTime t(int y, int mo, int d, int h, [int mi = 0]) =>
    DateTime.utc(y, mo, d, h, mi);

TimeEntry e(DateTime start, DateTime end, [int breakMinutes = 0]) =>
    TimeEntry(start: start, end: end, breakMinutes: breakMinutes);

const stage = TimeRules(minBreakPieceMinutes: 15);
const both = TimeRules(sundayHolidayRule: SundayHolidayRule.both);

void main() {
  group('entry totals: duration and working time', () {
    // Reference rows from the stage demo account (working_time).
    test('08:30 to 17:00 with 30 min break: 510 total, 480 working', () {
      final r = entryTotals(
        e(t(2026, 10, 15, 8, 30), t(2026, 10, 15, 17), 30),
        stage,
      );
      expect(
        (r.total, r.working, r.night, r.sunday, r.holiday),
        (510, 480, 0, 0, 0),
      );
    });

    test('08:30 to 17:15 with 30 min break: 525 total, 495 working', () {
      final r = entryTotals(
        e(t(2026, 10, 14, 8, 30), t(2026, 10, 14, 17, 15), 30),
        stage,
      );
      expect((r.total, r.working), (525, 495));
    });

    test('clock goes forward (29 Mar 2026): 01:00 to 04:00 is 2 hours', () {
      final r = entryTotals(e(t(2026, 3, 29, 1), t(2026, 3, 29, 4)), stage);
      expect(r.total, 120);
    });

    test('clock goes back (25 Oct 2026): 01:00 to 04:00 is 4 hours', () {
      final r = entryTotals(e(t(2026, 10, 25, 1), t(2026, 10, 25, 4)), stage);
      expect(r.total, 240);
    });
  });

  group('entry totals: night (22:00 to 06:00)', () {
    test('20:00 to 02:00: 4 night hours', () {
      final r = entryTotals(e(t(2026, 11, 18, 20), t(2026, 11, 19, 2)), stage);
      expect(r.night, 240);
    });

    test('04:00 to 08:00: 2 night hours in the morning', () {
      final r = entryTotals(e(t(2026, 11, 18, 4), t(2026, 11, 18, 8)), stage);
      expect(r.night, 120);
    });

    test('night minutes never exceed working minutes', () {
      final r = entryTotals(
        e(t(2026, 11, 18, 22), t(2026, 11, 19, 2), 30),
        stage,
      );
      expect((r.working, r.night), (210, 210));
    });
  });

  group('entry totals: Sunday and holiday', () {
    test('Sunday 08:00 to 17:00 with 30 min break: 510 Sunday minutes', () {
      final r = entryTotals(
        e(t(2026, 11, 22, 8), t(2026, 11, 22, 17), 30),
        both,
      );
      expect(r.sunday, 510);
    });

    test('Saturday 22:00 to Sunday 05:00: 5 Sunday hours, 7 night hours', () {
      final r = entryTotals(e(t(2026, 11, 21, 22), t(2026, 11, 22, 5)), both);
      expect((r.sunday, r.night), (300, 420));
    });

    // All 7 h fall in the Sunday window (it runs on to 04:00); the web
    // takes the legal break share (30 min above 6 h) off the Sunday
    // minutes even when no break was entered.
    test('Sunday 20:00 to Monday 03:00: 7 h Sunday, less 30 min share', () {
      final r = entryTotals(e(t(2026, 11, 22, 20), t(2026, 11, 23, 3)), both);
      expect(r.sunday, 390);
    });

    test('Monday 00:30 to 03:00 is not Sunday', () {
      final r = entryTotals(
        e(t(2026, 11, 23, 0, 30), t(2026, 11, 23, 3)),
        both,
      );
      expect(r.sunday, 0);
    });

    test('holiday on a Sunday, rule holiday only: holiday, not Sunday', () {
      final r = entryTotals(
        e(t(2026, 11, 22, 8), t(2026, 11, 22, 17), 30),
        stage,
        holidays: [t(2026, 11, 22, 0)],
      );
      expect((r.holiday, r.sunday), (510, 0));
    });

    test('holiday weekday 08:00 to 12:00: 4 holiday hours', () {
      final r = entryTotals(
        e(t(2026, 12, 25, 8), t(2026, 12, 25, 12)),
        stage,
        holidays: [t(2026, 12, 25, 0)],
      );
      expect(r.holiday, 240);
    });

    test('night into a holiday: only the part on the holiday counts', () {
      final r = entryTotals(
        e(t(2026, 12, 24, 20), t(2026, 12, 25, 6), 45),
        stage,
        holidays: [t(2026, 12, 25, 0)],
      );
      expect(r.holiday, 360);
    });

    test('a break longer than the time outside the holiday comes off it', () {
      final r = entryTotals(
        e(t(2026, 12, 24, 20), t(2026, 12, 25, 6), 300),
        stage,
        holidays: [t(2026, 12, 25, 0)],
      );
      expect((r.working, r.holiday), (300, 300));
    });
  });

  group('day check', () {
    test('8 h work with 30 min break is compliant', () {
      final c = checkDay([
        e(t(2026, 11, 18, 8), t(2026, 11, 18, 16, 30), 30),
      ], stage);
      expect((c.netWork, c.requiredBreak, c.compliant), (480, 30, true));
    });

    test('exactly 9 h needs only 30 min', () {
      final c = checkDay([
        e(t(2026, 11, 18, 8), t(2026, 11, 18, 17, 30), 30),
      ], stage);
      expect((c.netWork, c.requiredBreak, c.compliant), (540, 30, true));
    });

    test('one minute over 9 h needs 45 min: warning', () {
      final c = checkDay([
        e(t(2026, 11, 18, 8), t(2026, 11, 18, 17, 31), 30),
      ], stage);
      expect((c.netWork, c.requiredBreak, c.compliant), (541, 45, false));
    });

    test('a 30 min gap between two entries counts as break', () {
      final c = checkDay([
        e(t(2026, 11, 18, 8), t(2026, 11, 18, 12)),
        e(t(2026, 11, 18, 12, 30), t(2026, 11, 18, 17)),
      ], stage);
      expect((c.netWork, c.gapBreak, c.compliant), (510, 30, true));
    });

    test('a 10 min gap is below the minimum piece and does not count', () {
      final c = checkDay([
        e(t(2026, 11, 18, 8), t(2026, 11, 18, 12)),
        e(t(2026, 11, 18, 12, 10), t(2026, 11, 18, 17)),
      ], stage);
      expect((c.gapBreak, c.ignoredBreak, c.compliant), (0, 10, false));
    });

    test('a gap over 6 h starts a new working day', () {
      final c = checkDay([
        e(t(2026, 11, 18, 6), t(2026, 11, 18, 10)),
        e(t(2026, 11, 18, 17), t(2026, 11, 18, 21)),
      ], stage);
      expect(
        (c.netWork, c.gapBreak, c.requiredBreak, c.compliant),
        (480, 0, 0, true),
      );
    });

    test('attendance rule: 6 h of presence need 30 min', () {
      final entry = [e(t(2026, 11, 18, 8), t(2026, 11, 18, 14))];
      final attendance = checkDay(
        entry,
        const TimeRules(breakRule: BreakRule.attendance),
      );
      final statutory = checkDay(entry, stage);
      expect((attendance.requiredBreak, attendance.compliant), (30, false));
      expect((statutory.requiredBreak, statutory.compliant), (0, true));
    });

    test('long day above the warning threshold', () {
      final c = checkDay([
        e(t(2026, 11, 18, 6), t(2026, 11, 18, 17), 30),
      ], const TimeRules(maxWorkingHoursWarning: 10));
      expect(c.exceedsMaxWorkingHours, isTrue);
    });

    test('8 h rest between 22:00 and 06:00 is short of 11 h', () {
      final tuesday = e(t(2026, 11, 17, 6), t(2026, 11, 17, 14));
      final c = checkDay([
        e(t(2026, 11, 16, 14), t(2026, 11, 16, 22)),
        tuesday,
      ], const TimeRules(minRestHours: 11));
      expect(c.restShortfalls, hasLength(1));
      expect(c.restShortfalls.single.entry, same(tuesday));
      expect(c.restShortfalls.single.restMinutes, 480);
    });
  });

  group('suggested break', () {
    test('9 h alone: 30 min', () {
      expect(
        suggestBreak(e(t(2026, 11, 18, 7), t(2026, 11, 18, 16)), stage),
        30,
      );
    });

    test('9 h 35 alone: 35 min, which leaves exactly 9 h of work', () {
      expect(
        suggestBreak(e(t(2026, 11, 18, 7), t(2026, 11, 18, 16, 35)), stage),
        35,
      );
    });

    test('10 h alone: 45 min', () {
      expect(
        suggestBreak(e(t(2026, 11, 18, 7), t(2026, 11, 18, 17)), stage),
        45,
      );
    });

    test('a 15 min gap to the earlier entry counts towards it', () {
      expect(
        suggestBreak(
          e(t(2026, 11, 18, 11, 15), t(2026, 11, 18, 16)),
          stage,
          others: [e(t(2026, 11, 18, 7), t(2026, 11, 18, 11))],
        ),
        15,
      );
    });

    test('attendance rule: 6 h of presence: 30 min', () {
      expect(
        suggestBreak(
          e(t(2026, 11, 18, 8), t(2026, 11, 18, 14)),
          const TimeRules(breakRule: BreakRule.attendance),
        ),
        30,
      );
    });

    test('5 h: no break needed', () {
      expect(
        suggestBreak(e(t(2026, 11, 18, 8), t(2026, 11, 18, 13)), stage),
        0,
      );
    });
  });
}
