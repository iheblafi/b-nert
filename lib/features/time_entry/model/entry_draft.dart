import '../../times/domain/german_holidays.dart';
import '../../times/domain/german_time.dart';
import '../../times/domain/time_calc.dart';
import '../../times/domain/time_rules.dart';
import '../../times/model/overview_data.dart';
import '../../times/model/records.dart';
import '../../user_context/model/company_settings.dart';

/// What the user typed into the entry form (F3). Times are German wall
/// clock. An end before the start means the next day (night shift); an
/// end equal to the start is an error, not 24 hours.
class EntryDraft {
  const EntryDraft({
    required this.day,
    required this.start,
    required this.end,
    this.id,
    this.projectId,
    this.subprojectId,
    this.activityId,
    this.breakMinutes = 0,
    this.night,
    this.sunday,
    this.holiday,
    this.workPlace,
    this.holidayState,
    this.location = '',
    this.remarks = '',
  });

  /// Id of the entry being edited; null for a new one.
  final String? id;
  final String? projectId;
  final String? subprojectId;
  final String? activityId;
  final DateTime day;
  final ClockTime start;
  final ClockTime end;
  final int breakMinutes;

  /// Surcharge minutes typed by hand; null: calculated.
  final int? night;
  final int? sunday;
  final int? holiday;
  final WorkPlace? workPlace;
  final String? holidayState;
  final String location;
  final String remarks;

  DateTime get startAt => GermanTime.atTime(day, start.hour, start.minute);

  bool get endsNextDay =>
      end.hour * 60 + end.minute < start.hour * 60 + start.minute;

  DateTime get endAt => GermanTime.atTime(
    endsNextDay ? GermanTime.addDays(day, 1) : day,
    end.hour,
    end.minute,
  );

  TimeEntry get time =>
      TimeEntry(id: id, start: startAt, end: endAt, breakMinutes: breakMinutes);

  EntryDraft copyWith({
    String? projectId,
    String? Function()? subprojectId,
    String? Function()? activityId,
    DateTime? day,
    ClockTime? start,
    ClockTime? end,
    int? breakMinutes,
    int? Function()? night,
    int? Function()? sunday,
    int? Function()? holiday,
    WorkPlace? Function()? workPlace,
    String? Function()? holidayState,
    String? location,
    String? remarks,
  }) => EntryDraft(
    id: id,
    projectId: projectId ?? this.projectId,
    subprojectId: subprojectId == null ? this.subprojectId : subprojectId(),
    activityId: activityId == null ? this.activityId : activityId(),
    day: day ?? this.day,
    start: start ?? this.start,
    end: end ?? this.end,
    breakMinutes: breakMinutes ?? this.breakMinutes,
    night: night == null ? this.night : night(),
    sunday: sunday == null ? this.sunday : sunday(),
    holiday: holiday == null ? this.holiday : holiday(),
    workPlace: workPlace == null ? this.workPlace : workPlace(),
    holidayState: holidayState == null ? this.holidayState : holidayState(),
    location: location ?? this.location,
    remarks: remarks ?? this.remarks,
  );
}

enum EntryField { project, end, breakMinutes, night, sunday, holiday, date }

enum EntryError {
  noProject,
  endNotAfterStart,
  longerThan24h,
  breakLongerThanEntry,
  surchargeAboveWorking,
  overlap,
  absenceBlocks,
  locked,
}

sealed class EntryWarning {
  const EntryWarning();
}

class BreakTooShort extends EntryWarning {
  const BreakTooShort(this.required);
  final int required;
}

class LongDay extends EntryWarning {
  const LongDay(this.limitHours);
  final int limitHours;
}

class RestTooShort extends EntryWarning {
  const RestTooShort({required this.rest, required this.required});
  final int rest;
  final int required;
}

class OnAbsenceDay extends EntryWarning {
  const OnAbsenceDay(this.type);
  final AbsenceType type;
}

/// Saved later than the company's maximum delay: needs approval (AC5).
class NeedsApproval extends EntryWarning {
  const NeedsApproval();
}

/// The checks of one draft: errors block saving, warnings do not.
class EntryCheck {
  const EntryCheck({
    required this.totals,
    required this.suggestedBreak,
    required this.errors,
    required this.warnings,
    required this.comparedWithOthers,
  });

  /// Calculated minutes; hand-typed surcharges already applied.
  final EntryTotals totals;
  final int suggestedBreak;
  final Map<EntryField, EntryError> errors;
  final List<EntryWarning> warnings;

  /// False when the user's other entries were not loaded, so overlap,
  /// break across entries and rest time could not be checked.
  final bool comparedWithOthers;

  bool get canSave => errors.isEmpty;
}

/// The holidays that apply to the entry: those of [holidayState] when the
/// user picked one, otherwise the user's own from [overview].
List<DateTime> holidaysForEntry(EntryDraft d, OverviewData? overview) {
  if (d.holidayState case final state?) {
    final days = <DateTime>[];
    for (var y = d.day.year; y <= d.endAt.year; y++) {
      for (final h in publicHolidays(y, state)) {
        if (!h.regional) days.add(h.date);
      }
    }
    return days;
  }
  return overview?.holidays.keys.toList() ?? const [];
}

/// Checks [draft] like the web form and its server action (spec F3,
/// docs/research/web-calculation-rules.md). [overview] holds the user's
/// other entries and absences; null when not loaded. [now] is German
/// wall-clock time. [locked] is true for a closed or invoiced entry.
EntryCheck checkDraft(
  EntryDraft draft, {
  required CompanySettings settings,
  required DateTime now,
  OverviewData? overview,
  bool locked = false,
}) {
  final rules = settings.timeRules;
  final time = draft.time;
  final calc = entryTotals(
    time,
    rules,
    holidays: holidaysForEntry(draft, overview),
  );
  final totals = EntryTotals(
    total: calc.total,
    working: calc.working,
    night: settings.showSurchargeTimes ? draft.night ?? calc.night : 0,
    sunday: settings.showSurchargeTimes ? draft.sunday ?? calc.sunday : 0,
    holiday: settings.showSurchargeTimes ? draft.holiday ?? calc.holiday : 0,
  );

  final others = <TimeEntry>[
    for (final e in overview?.entries ?? const <TimeRecord>[])
      if (e.id != draft.id && e.counts) e.time,
  ];
  // Like the web: the user's entries from 3 days before to 3 days after.
  // checkDay splits them into shifts itself.
  final nearby = [
    for (final o in others)
      if (GermanTime.minutesBetween(o.end, time.start) <= 3 * 24 * 60 &&
          GermanTime.minutesBetween(time.end, o.start) <= 3 * 24 * 60)
        o,
  ];

  final errors = <EntryField, EntryError>{};
  if (locked) errors[EntryField.date] = EntryError.locked;
  if (draft.projectId == null) {
    errors[EntryField.project] = EntryError.noProject;
  }
  if (calc.total <= 0) {
    errors[EntryField.end] = EntryError.endNotAfterStart;
  } else if (calc.total > 24 * 60) {
    errors[EntryField.end] = EntryError.longerThan24h;
  } else if (nearby.any((o) => _overlaps(o, time))) {
    errors[EntryField.end] = EntryError.overlap;
  }
  if (draft.breakMinutes > calc.total) {
    errors[EntryField.breakMinutes] = EntryError.breakLongerThanEntry;
  }
  if (totals.night > totals.working) {
    errors[EntryField.night] = EntryError.surchargeAboveWorking;
  }
  if (totals.sunday > totals.working) {
    errors[EntryField.sunday] = EntryError.surchargeAboveWorking;
  }
  if (totals.holiday > totals.working) {
    errors[EntryField.holiday] = EntryError.surchargeAboveWorking;
  }

  final warnings = <EntryWarning>[];
  final absence = overview?.absenceOn(draft.day);
  if (absence != null) {
    switch (settings.entryDuringAbsence) {
      case EntryDuringAbsence.block:
        errors[EntryField.date] ??= EntryError.absenceBlocks;
      case EntryDuringAbsence.warn:
        warnings.add(OnAbsenceDay(absence.type));
      case EntryDuringAbsence.allow:
        break;
    }
  }

  var suggested = 0;
  // Break figures mean nothing while the entry overlaps another one.
  if (calc.total > 0 &&
      calc.total <= 24 * 60 &&
      errors[EntryField.end] != EntryError.overlap) {
    // Break: only the shift of this entry. Long day and rest time: the
    // whole window, as the web does.
    final shiftMates = _sameShift(time, nearby, rules.shiftBoundaryHours);
    final shift = checkDay([...shiftMates, time], rules, day: draft.day);
    if (!shift.compliant) warnings.add(BreakTooShort(shift.requiredBreak));
    final day = checkDay([...nearby, time], rules, day: draft.day);
    if (day.exceedsMaxWorkingHours) {
      warnings.add(LongDay(rules.maxWorkingHoursWarning!));
    }
    for (final r in day.restShortfalls) {
      if (r.entry.id == draft.id && r.entry.start == time.start) {
        warnings.add(
          RestTooShort(rest: r.restMinutes, required: rules.minRestHours! * 60),
        );
      }
    }
    suggested = suggestBreak(time, rules, others: shiftMates);
  }

  final maxDelay = settings.maxDelayHours;
  if (maxDelay != null &&
      calc.total > 0 &&
      GermanTime.minutesBetween(time.end, now) > maxDelay * 60) {
    warnings.add(const NeedsApproval());
  }

  return EntryCheck(
    totals: totals,
    suggestedBreak: suggested,
    errors: errors,
    warnings: warnings,
    comparedWithOthers: overview != null,
  );
}

/// Entries chained to [entry] by gaps of at most [boundaryHours].
List<TimeEntry> _sameShift(
  TimeEntry entry,
  List<TimeEntry> others,
  int boundaryHours,
) {
  final limit = boundaryHours * 60;
  final shift = <TimeEntry>[entry];
  final rest = [...others];
  var grew = true;
  while (grew) {
    grew = false;
    for (final o in [...rest]) {
      final close = shift.any(
        (s) =>
            GermanTime.minutesBetween(o.end, s.start) <= limit &&
            GermanTime.minutesBetween(s.end, o.start) <= limit,
      );
      if (close) {
        shift.add(o);
        rest.remove(o);
        grew = true;
      }
    }
  }
  return shift.skip(1).toList();
}

bool _overlaps(TimeEntry a, TimeEntry b) =>
    GermanTime.minutesBetween(b.start, a.end) > 0 &&
    GermanTime.minutesBetween(a.start, b.end) > 0;
