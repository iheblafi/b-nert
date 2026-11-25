import '../domain/expected_time.dart';
import '../domain/german_time.dart';
import '../domain/time_calc.dart';
import '../domain/time_rules.dart';
import 'records.dart';

/// What the overview (F2) shows for a stretch of days, from the backend or
/// from sample data. All day keys are midnight UTC wall-clock dates.
class OverviewData {
  OverviewData({
    required this.today,
    required this.rules,
    required this.entries,
    required this.holidays,
    required this.absences,
    this.halfDayHolidays = const {},
    this.expected = ExpectedTime.fallback,
    this.overtime,
    this.from,
    this.to,
    this.loadedAt,
    this.incomplete = const {},
  });

  final DateTime today;
  final TimeRules rules;
  final List<TimeRecord> entries;

  /// Public and company holidays by day, with their names.
  final Map<DateTime, String> holidays;

  /// Holidays in [holidays] that free only half the day.
  final Set<DateTime> halfDayHolidays;
  final List<AbsenceRecord> absences;
  final ExpectedTime expected;

  /// Null hides the overtime card (company setting or no data).
  final OvertimeSummary? overtime;

  /// Loaded range, both inclusive; null for sample data (any day).
  final DateTime? from;
  final DateTime? to;

  /// When it was loaded; null for sample data.
  final DateTime? loadedAt;

  /// Parts that could not be loaded; the screen says the figures may be off.
  final Set<OverviewPart> incomplete;

  bool contains(DateTime day) =>
      from == null || (!day.isBefore(from!) && !day.isAfter(to!));

  List<TimeRecord> entriesOn(DateTime day) {
    final d = GermanTime.startOfDay(day);
    return entries.where((e) => e.day == d).toList()
      ..sort((a, b) => a.time.start.compareTo(b.time.start));
  }

  int workedOn(DateTime day) =>
      entriesOn(day)
          .where((e) => e.counts)
          .fold(0, (s, e) => s + e.totals(rules).working);

  int nightOn(DateTime day) =>
      entriesOn(day)
          .where((e) => e.counts)
          .fold(0, (s, e) => s + e.totals(rules).night);

  /// An approved absence that frees at least part of [day].
  AbsenceRecord? absenceOn(DateTime day) {
    final d = GermanTime.startOfDay(day);
    for (final a in absences) {
      if (a.status == RequestStatus.approved && a.shareOn(d) > 0) return a;
    }
    return null;
  }

  double _holidayShare(DateTime d) => !holidays.containsKey(d)
      ? 0
      : halfDayHolidays.contains(d)
      ? 0.5
      : 1;

  double _absenceShare(DateTime d) => absences
      .where((a) => a.status == RequestStatus.approved)
      .fold(0.0, (s, a) => s + a.shareOn(d))
      .clamp(0, 1)
      .toDouble();

  int expectedOn(DateTime day) {
    final d = GermanTime.startOfDay(day);
    return expected.on(
      d,
      holidayShare: _holidayShare(d),
      absenceShare: _absenceShare(d),
    );
  }

  DayStatus statusOf(DateTime day) {
    final d = GermanTime.startOfDay(day);
    final worked = workedOn(d);
    if (d.isAfter(today)) return DayStatus.future;
    if (_holidayShare(d) == 1) return DayStatus.holiday;
    if (_absenceShare(d) == 1) return DayStatus.absent;
    final target = expectedOn(d);
    // No target (weekend, or a free day in the work time model).
    if (target == 0) return worked > 0 ? DayStatus.complete : DayStatus.weekend;
    if (worked >= target) return DayStatus.complete;
    return worked > 0 ? DayStatus.incomplete : DayStatus.missing;
  }

  DayCheck checkOn(DateTime day) => checkDay(
    entriesOn(day).where((e) => e.counts).map((e) => e.time).toList(),
    rules,
  );
}

enum OverviewPart { holidays, workTimeModel, absences, overtime }
