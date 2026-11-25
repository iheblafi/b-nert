import '../domain/expected_time.dart';
import '../domain/german_holidays.dart';
import '../domain/time_calc.dart';
import '../domain/time_rules.dart';
import '../model/records.dart';

// Backend rows (PostgREST JSON) to the overview's model. Pure, so the
// column handling is tested without a backend. Columns as documented in
// docs/research/web-app-analysis.md section 6 and seen in the demo rows.

/// "2026-10-15T08:30:00" (timestamp without time zone) as a wall-clock
/// DateTime in UTC fields. An offset, if present, is ignored.
DateTime parseWall(String s) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2}))?')
      .firstMatch(s);
  if (m == null) throw FormatException('Not a date', s);
  int n(int i) => int.parse(m[i] ?? '0');
  return DateTime.utc(n(1), n(2), n(3), n(4), n(5));
}

/// The date part as "YYYY-MM-DD".
String isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

int _int(Object? v) => (v as num?)?.round() ?? 0;

String? _text(Object? v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}

Map<String, dynamic>? _obj(Object? v) => v is Map<String, dynamic> ? v : null;

TimeRecord timeRecordFromRow(Map<String, dynamic> r) {
  final project = _obj(r['project']);
  return TimeRecord(
    id: r['id'] as String,
    project: ProjectRef(
      _text(project?['project_number']) ?? '',
      _text(project?['name']) ?? '',
      id: r['project_id'] as String? ?? project?['id'] as String?,
    ),
    activity: _text(_obj(r['activity'])?['name']) ?? '',
    subproject: _text(_obj(r['subproject'])?['name']),
    time: TimeEntry(
      id: r['id'] as String,
      start: parseWall(r['start_date'] as String),
      end: parseWall(r['end_date'] as String),
      breakMinutes: _int(r['minutes_break']),
    ),
    status: switch (r['status']) {
      'closed' => EntryStatus.closed,
      'invoiced' => EntryStatus.invoiced,
      _ => r['closed'] == true ? EntryStatus.closed : EntryStatus.open,
    },
    delay: switch (r['delay_status']) {
      'pending' => DelayStatus.pending,
      'approved' => DelayStatus.approved,
      'rejected' => DelayStatus.rejected,
      _ => DelayStatus.none,
    },
    workPlace: switch (r['work_place']) {
      'office' => WorkPlace.office,
      'home' => WorkPlace.home,
      'away' => WorkPlace.away,
      _ => null,
    },
    location: _text(r['location']),
    holidayState: _text(r['holiday_state']),
    remarks: _text(r['remarks']),
    createdInApp: r['platform_id'] == 'app',
    stored: EntryTotals(
      total: _int(r['minutes']),
      working: _int(r['minutes_working']),
      night: _int(r['minutes_night']),
      sunday: _int(r['minutes_sunday']),
      holiday: _int(r['minutes_feast']),
    ),
  );
}

AbsenceRecord? absenceFromRow(Map<String, dynamic> r) {
  final type = switch (_obj(r['account_category'])?['name']) {
    'vacation' => AbsenceType.vacation,
    'sick' => AbsenceType.sick,
    'overtime' => AbsenceType.overtime,
    'training' => AbsenceType.training,
    'special' => AbsenceType.special,
    _ => null,
  };
  final status = switch (r['request_status_type_id']) {
    'pending' => RequestStatus.pending,
    'approved' => RequestStatus.approved,
    'rejected' => RequestStatus.rejected,
    'cancelled' => RequestStatus.cancelled,
    _ => null,
  };
  if (type == null || status == null) return null;
  return AbsenceRecord(
    type: type,
    from: parseWall(r['start_date'] as String),
    to: parseWall(r['end_date'] as String),
    days: (r['total_working_days'] as num?)?.toDouble() ?? 0,
    status: status,
    note: _text(r['training_title']) ?? _text(r['remarks']),
    firstDayAfternoonOnly: r['first_day_afternoon_only'] == true,
    lastDayMorningOnly: r['last_day_morning_only'] == true,
    hourly: r['hours'] != null && (r['hours'] as num) > 0,
  );
}

const _weekdays = [
  'monday_hours',
  'tuesday_hours',
  'wednesday_hours',
  'thursday_hours',
  'friday_hours',
  'saturday_hours',
  'sunday_hours',
];

/// [assignments]: user_work_time_model rows; [hours]: work_time_model_daily_hours
/// rows (id = model id).
ExpectedTime expectedFromRows(
  List<Map<String, dynamic>> assignments,
  List<Map<String, dynamic>> hours,
) {
  final byModel = {for (final h in hours) h['id'] as String: h};
  final periods = <WorkTimeModelPeriod>[];
  for (final a in assignments) {
    final h = byModel[a['work_time_model_id']];
    if (h == null) continue;
    periods.add(
      WorkTimeModelPeriod(
        from: parseWall(a['start_date'] as String),
        to: a['end_date'] == null ? null : parseWall(a['end_date'] as String),
        minutesByWeekday: [
          for (final k in _weekdays) (((h[k] as num?) ?? 0) * 60).round(),
        ],
      ),
    );
  }
  periods.sort((a, b) => b.from.compareTo(a.from));
  return ExpectedTime(periods);
}

/// The place of employment that applies on [day]: the assignment covering
/// it, else the most recent one.
String? placeOn(List<Map<String, dynamic>> assignments, DateTime day) {
  final sorted = [...assignments]
    ..sort(
      (a, b) =>
          (b['start_date'] as String).compareTo(a['start_date'] as String),
    );
  for (final a in sorted) {
    final from = parseWall(a['start_date'] as String);
    final to = a['end_date'] == null
        ? null
        : parseWall(a['end_date'] as String);
    if (!day.isBefore(from) && (to == null || !day.isAfter(to))) {
      return a['place_of_employment_id'] as String?;
    }
  }
  return sorted.isEmpty
      ? null
      : sorted.first['place_of_employment_id'] as String?;
}

/// Public holidays of [state] in [from]..[to], adjusted by the company's
/// per-location switches, plus company holidays ([custom]: custom_holidays
/// rows already filtered to this location or all locations).
({Map<DateTime, String> names, Set<DateTime> halfDays}) holidaysFor({
  required DateTime from,
  required DateTime to,
  String? state,
  Set<String> deactivated = const {},
  Set<String> activated = const {},
  List<Map<String, dynamic>> custom = const [],
}) {
  final names = <DateTime, String>{};
  final half = <DateTime>{};
  if (state != null) {
    for (var y = from.year; y <= to.year; y++) {
      for (final h in publicHolidays(y, state)) {
        if (h.date.isBefore(from) || h.date.isAfter(to)) continue;
        if (deactivated.contains(h.name)) continue;
        if (h.regional && !activated.contains(h.name)) continue;
        names[h.date] = h.name;
      }
    }
  }
  for (final c in custom) {
    if (c['active'] == false) continue;
    final d = parseWall(c['date'] as String);
    if (d.isBefore(from) || d.isAfter(to)) continue;
    final isHalf = c['half_day'] == true;
    // A public holiday on the same day stays a full day off.
    if (names.containsKey(d) && !half.contains(d)) continue;
    names[d] = _text(c['name']) ?? '';
    if (isHalf) half.add(d);
  }
  return (names: names, halfDays: half);
}
