/// Expected working time ("Soll") per day.
///
/// PROVISIONAL until the backend offers it (R-BE-3): the web computes it
/// in a server action (getDailyExpectationsForRange) that the app cannot
/// call. Rebuilt from what the analysis found: the user's work time model
/// (hours per weekday, with validity dates), minus public and company
/// holidays and approved absences. Without any model the web assumes
/// Monday to Friday, 8 hours.
library;

import 'dart:math' as math;

class WorkTimeModelPeriod {
  const WorkTimeModelPeriod({
    required this.from,
    required this.minutesByWeekday,
    this.to,
  });

  /// First day the model applies.
  final DateTime from;

  /// Last day it applies; null: open-ended.
  final DateTime? to;

  /// Monday first, 7 values.
  final List<int> minutesByWeekday;

  bool covers(DateTime day) =>
      !day.isBefore(from) && (to == null || !day.isAfter(to!));
}

class ExpectedTime {
  const ExpectedTime(this.periods);

  /// The web's fallback: Monday to Friday, 8 hours.
  static const fallback = ExpectedTime([]);

  final List<WorkTimeModelPeriod> periods;

  /// True when no model is assigned and the fallback is used.
  bool get assumed => periods.isEmpty;

  /// Model minutes for [day] before holidays and absences. A day outside
  /// every assigned period has no target.
  int baseOn(DateTime day) {
    if (periods.isEmpty) return day.weekday <= DateTime.friday ? 480 : 0;
    for (final p in periods) {
      if (p.covers(day)) return p.minutesByWeekday[day.weekday - 1];
    }
    return 0;
  }

  /// [holidayShare] and [absenceShare] are 0, 0.5 or 1 of the day.
  int on(DateTime day, {double holidayShare = 0, double absenceShare = 0}) {
    final free = math.min(1.0, holidayShare + absenceShare);
    return (baseOn(day) * (1 - free)).round();
  }
}
