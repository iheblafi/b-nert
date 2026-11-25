import '../../times/domain/time_rules.dart' as calc;

/// The company settings the app needs (table time_management.setting).
/// Unknown or missing values fall back to the web app's defaults.
class CompanySettings {
  const CompanySettings({
    this.breakRule = BreakRule.statutory,
    this.minBreakPieceMinutes = 15,
    this.maxDelayHours,
    this.showSubproject = true,
    this.showActivity = true,
    this.showSurchargeTimes = true,
    this.showOvertimeCard = false,
    this.colleagueAbsenceVisibility = ColleagueAbsenceVisibility.none,
    this.missingEntryReminderTime,
    this.defaultStartTime = (hour: 8, minute: 0),
    this.defaultEndTime = (hour: 16, minute: 30),
    this.nightStart = (hour: 22, minute: 0),
    this.nightEnd = (hour: 6, minute: 0),
    this.shiftBoundaryHours = 6,
    this.sundayHolidayRule = calc.SundayHolidayRule.holidayOnly,
    this.maxWorkingHoursWarning,
    this.minRestHours,
    this.entryDuringAbsence = EntryDuringAbsence.warn,
    this.showHolidayState = false,
    this.furtherDetails = FurtherDetailsMode.open,
    this.workPlaceMode = WorkPlaceMode.off,
  });

  factory CompanySettings.fromJson(Map<String, dynamic> j) => CompanySettings(
    breakRule: j['break_rule'] == 'attendance'
        ? BreakRule.attendance
        : BreakRule.statutory,
    minBreakPieceMinutes: (j['min_break_piece_minutes'] as num?)?.toInt() ?? 15,
    maxDelayHours: (j['max_delay_hours'] as num?)?.toInt(),
    showSubproject: j['show_subproject'] as bool? ?? true,
    showActivity: j['show_activity'] as bool? ?? true,
    showSurchargeTimes: j['show_surcharge_times'] as bool? ?? true,
    showOvertimeCard: j['show_overtime_card'] as bool? ?? false,
    colleagueAbsenceVisibility: switch (j['colleague_absence_visibility']) {
      'presence' => ColleagueAbsenceVisibility.presence,
      'category' => ColleagueAbsenceVisibility.category,
      _ => ColleagueAbsenceVisibility.none,
    },
    missingEntryReminderTime: j['missing_time_entry_reminder_time'] as String?,
    defaultStartTime:
        parseClock(j['default_start_time']) ?? (hour: 8, minute: 0),
    defaultEndTime: parseClock(j['default_end_time']) ?? (hour: 16, minute: 30),
    nightStart: parseClock(j['start_night_time']) ?? (hour: 22, minute: 0),
    nightEnd: parseClock(j['end_night_time']) ?? (hour: 6, minute: 0),
    shiftBoundaryHours: (j['shift_boundary_hours'] as num?)?.toInt() ?? 6,
    sundayHolidayRule: j['sunday_holiday_rule'] == 'both'
        ? calc.SundayHolidayRule.both
        : calc.SundayHolidayRule.holidayOnly,
    maxWorkingHoursWarning: (j['max_working_hours_warning'] as num?)?.toInt(),
    minRestHours: (j['min_rest_hours'] as num?)?.toInt(),
    entryDuringAbsence: switch (j['time_entry_during_absence']) {
      'allow' => EntryDuringAbsence.allow,
      'block' => EntryDuringAbsence.block,
      _ => EntryDuringAbsence.warn,
    },
    showHolidayState: j['show_holiday_state'] as bool? ?? false,
    furtherDetails: switch (j['further_details_mode']) {
      'collapsed' => FurtherDetailsMode.collapsed,
      'hidden' => FurtherDetailsMode.hidden,
      _ => FurtherDetailsMode.open,
    },
    workPlaceMode: switch (j['work_place_mode']) {
      'record' => WorkPlaceMode.record,
      'plan' => WorkPlaceMode.plan,
      _ => WorkPlaceMode.off,
    },
  );

  final BreakRule breakRule;
  final int minBreakPieceMinutes;
  final int? maxDelayHours;
  final bool showSubproject;
  final bool showActivity;
  final bool showSurchargeTimes;
  final bool showOvertimeCard;
  final ColleagueAbsenceVisibility colleagueAbsenceVisibility;

  /// "HH:MM:SS", null when the company switched the reminder off.
  final String? missingEntryReminderTime;
  final calc.ClockTime defaultStartTime;
  final calc.ClockTime defaultEndTime;
  final calc.ClockTime nightStart;
  final calc.ClockTime nightEnd;
  final int shiftBoundaryHours;
  final calc.SundayHolidayRule sundayHolidayRule;
  final int? maxWorkingHoursWarning;
  final int? minRestHours;
  final EntryDuringAbsence entryDuringAbsence;
  final bool showHolidayState;
  final FurtherDetailsMode furtherDetails;
  final WorkPlaceMode workPlaceMode;

  /// The rules for the time calculation (b8).
  calc.TimeRules get timeRules => calc.TimeRules(
    breakRule: breakRule == BreakRule.attendance
        ? calc.BreakRule.attendance
        : calc.BreakRule.statutory,
    minBreakPieceMinutes: minBreakPieceMinutes,
    shiftBoundaryHours: shiftBoundaryHours,
    nightStart: nightStart,
    nightEnd: nightEnd,
    sundayHolidayRule: sundayHolidayRule,
    maxWorkingHoursWarning: maxWorkingHoursWarning,
    minRestHours: minRestHours,
  );

  Map<String, dynamic> toJson() => {
    'break_rule': breakRule.name,
    'min_break_piece_minutes': minBreakPieceMinutes,
    'max_delay_hours': maxDelayHours,
    'show_subproject': showSubproject,
    'show_activity': showActivity,
    'show_surcharge_times': showSurchargeTimes,
    'show_overtime_card': showOvertimeCard,
    'colleague_absence_visibility': colleagueAbsenceVisibility.name,
    'missing_time_entry_reminder_time': missingEntryReminderTime,
    'default_start_time': _clock(defaultStartTime),
    'default_end_time': _clock(defaultEndTime),
    'start_night_time': _clock(nightStart),
    'end_night_time': _clock(nightEnd),
    'shift_boundary_hours': shiftBoundaryHours,
    'sunday_holiday_rule': sundayHolidayRule == calc.SundayHolidayRule.both
        ? 'both'
        : 'holiday_only',
    'max_working_hours_warning': maxWorkingHoursWarning,
    'min_rest_hours': minRestHours,
    'time_entry_during_absence': entryDuringAbsence.name,
    'show_holiday_state': showHolidayState,
    'further_details_mode': furtherDetails.name,
    'work_place_mode': workPlaceMode.name,
  };
}

/// "HH:MM" or "HH:MM:SS"; null when missing or malformed.
calc.ClockTime? parseClock(Object? v) {
  if (v is! String) return null;
  final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(v);
  if (m == null) return null;
  return (hour: int.parse(m[1]!), minute: int.parse(m[2]!));
}

String _clock(calc.ClockTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

enum BreakRule { statutory, attendance }

enum ColleagueAbsenceVisibility { none, presence, category }

enum EntryDuringAbsence { allow, warn, block }

enum FurtherDetailsMode { open, collapsed, hidden }

enum WorkPlaceMode { off, record, plan }
