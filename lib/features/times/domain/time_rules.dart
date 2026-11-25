/// The company settings the time calculation needs
/// (time_management.setting), with the web app's defaults.
enum BreakRule {
  /// Arbeitszeitgesetz: 30 min above 6 h of work, 45 above 9 h.
  statutory,

  /// Company rule by presence: 30 min from 6 h, 45 from 9.5 h.
  attendance,
}

enum SundayHolidayRule {
  /// A Sunday that is a holiday counts as holiday only.
  holidayOnly,

  /// It counts as both.
  both,
}

/// A clock time, e.g. the start of the night window.
typedef ClockTime = ({int hour, int minute});

class TimeRules {
  const TimeRules({
    this.breakRule = BreakRule.statutory,
    this.minBreakPieceMinutes,
    this.shiftBoundaryHours = 6,
    this.nightStart = (hour: 22, minute: 0),
    this.nightEnd = (hour: 6, minute: 0),
    this.sundayHolidayRule = SundayHolidayRule.holidayOnly,
    this.maxWorkingHoursWarning,
    this.minRestHours,
  });

  final BreakRule breakRule;

  /// Breaks and gaps shorter than this do not count; null: all count.
  final int? minBreakPieceMinutes;

  /// A gap longer than this starts a new working day (shift).
  final int shiftBoundaryHours;
  final ClockTime nightStart;
  final ClockTime nightEnd;
  final SundayHolidayRule sundayHolidayRule;

  /// Warn above this many hours of work on one day; null: no warning.
  final int? maxWorkingHoursWarning;

  /// Rest between working days; null: not checked.
  final int? minRestHours;
}

/// One time entry. Start and end are German wall-clock times, the way
/// the backend stores them (BR-18): only year to minute are read, the
/// time zone of the DateTime is ignored.
class TimeEntry {
  const TimeEntry({
    required this.start,
    required this.end,
    this.breakMinutes = 0,
    this.id,
  });

  final DateTime start;
  final DateTime end;
  final int breakMinutes;
  final String? id;
}
