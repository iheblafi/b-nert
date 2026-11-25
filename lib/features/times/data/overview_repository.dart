import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../../user_context/model/company_settings.dart';
import '../domain/expected_time.dart';
import '../model/overview_data.dart';
import '../model/records.dart';
import 'overview_rows.dart';

abstract interface class OverviewRepository {
  /// The user's entries, holidays, absences, work time model and overtime
  /// for [from]..[to] (both inclusive, wall-clock dates). Read only.
  /// Throws [AppFailure] when the entries cannot be loaded; the other
  /// parts fail softly and are listed in [OverviewData.incomplete].
  Future<OverviewData> load({
    required String userId,
    required DateTime from,
    required DateTime to,
    required DateTime today,
    required CompanySettings settings,
  });
}

/// Reads time_management tables with the user's own token. Never writes.
class SupabaseOverviewRepository implements OverviewRepository {
  SupabaseOverviewRepository(this._client, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final SupabaseClient _client;
  final DateTime Function() _now;

  PostgrestQueryBuilder<dynamic> _tm(String table) =>
      _client.schema('time_management').from(table);

  static const _entryColumns =
      'id, project_id, start_date, end_date, minutes, minutes_break, '
      'minutes_working, minutes_night, minutes_sunday, minutes_feast, '
      'location, remarks, work_place, holiday_state, platform_id, status, '
      'closed, delay_status, project(id, project_number, name), '
      'activity(name), subproject(name)';

  @override
  Future<OverviewData> load({
    required String userId,
    required DateTime from,
    required DateTime to,
    required DateTime today,
    required CompanySettings settings,
  }) async {
    final incomplete = <OverviewPart>{};
    Future<T> soft<T>(OverviewPart part, T fallback, Future<T> Function() f) =>
        f().catchError((Object _) {
          incomplete.add(part);
          return fallback;
        });

    // Started together; only the entries may fail the whole load.
    final absences = soft(OverviewPart.absences, <AbsenceRecord>[], () {
      return _absences(userId, from, to);
    });
    final expected = soft(
      OverviewPart.workTimeModel,
      ExpectedTime.fallback,
      () {
        return _expected(userId);
      },
    );
    final holidays = soft(OverviewPart.holidays, (
      names: <DateTime, String>{},
      halfDays: <DateTime>{},
    ), () => _holidays(userId, from, to, today));
    final overtime = settings.showOvertimeCard
        ? soft<OvertimeSummary?>(OverviewPart.overtime, null, () {
            return _overtime(userId);
          })
        : Future<OvertimeSummary?>.value();
    final List<TimeRecord> entries;
    try {
      entries = await _entries(userId, from, to);
    } on Object catch (e) {
      throw AppFailure.from(e);
    }
    final h = await holidays;
    return OverviewData(
      today: today,
      rules: settings.timeRules,
      entries: entries,
      holidays: h.names,
      halfDayHolidays: h.halfDays,
      absences: await absences,
      expected: await expected,
      overtime: await overtime,
      from: from,
      to: to,
      loadedAt: _now(),
      incomplete: incomplete,
    );
  }

  Future<List<TimeRecord>> _entries(
    String userId,
    DateTime from,
    DateTime to,
  ) async {
    // Entries that end on or after the first day and start before the day
    // after the last: night shifts across the edge are included.
    final rows = await _tm('working_time')
        .select(_entryColumns)
        .eq('user_id', userId)
        .gte('end_date', isoDay(from))
        .lt('start_date', isoDay(to.add(const Duration(days: 1))))
        .order('start_date');
    return rows.map(timeRecordFromRow).toList();
  }

  Future<List<AbsenceRecord>> _absences(
    String userId,
    DateTime from,
    DateTime to,
  ) async {
    final rows = await _tm('account_request')
        .select(
          'start_date, end_date, first_day_afternoon_only, '
          'last_day_morning_only, total_working_days, hours, '
          'request_status_type_id, remarks, training_title, '
          'account_category(name)',
        )
        .eq('user_id', userId)
        .inFilter('request_status_type_id', ['approved', 'pending'])
        .lte('start_date', isoDay(to))
        .gte('end_date', isoDay(from));
    return rows.map(absenceFromRow).nonNulls.toList();
  }

  Future<ExpectedTime> _expected(String userId) async {
    final assignments = await _tm('user_work_time_model')
        .select('work_time_model_id, start_date, end_date')
        .eq('user_id', userId);
    if (assignments.isEmpty) return ExpectedTime.fallback;
    final ids = assignments
        .map((a) => a['work_time_model_id'] as String)
        .toSet()
        .toList();
    final hours = await _tm('work_time_model_daily_hours')
        .select()
        .inFilter('id', ids);
    return expectedFromRows(assignments, hours);
  }

  Future<({Map<DateTime, String> names, Set<DateTime> halfDays})> _holidays(
    String userId,
    DateTime from,
    DateTime to,
    DateTime today,
  ) async {
    final places = await _tm('user_place_of_employment')
        .select('place_of_employment_id, start_date, end_date')
        .eq('user_id', userId);
    final placeId = placeOn(places, today);
    String? state;
    var deactivated = <String>{};
    var activated = <String>{};
    if (placeId != null) {
      final (place, off, on) = await (
        _client
            .schema('tenant')
            .from('place_of_employment')
            .select('state')
            .eq('id', placeId)
            .maybeSingle(),
        _tm('official_holiday_deactivated')
            .select('holiday_name')
            .eq('place_of_employment_id', placeId),
        _tm('official_holiday_activated')
            .select('holiday_name')
            .eq('place_of_employment_id', placeId),
      ).wait;
      state = place?['state'] as String?;
      deactivated = {for (final r in off) r['holiday_name'] as String};
      activated = {for (final r in on) r['holiday_name'] as String};
    }
    final custom = await _tm('custom_holidays')
        .select('name, date, half_day, active, place_of_employment_id')
        .gte('date', isoDay(from))
        .lte('date', isoDay(to));
    return holidaysFor(
      from: from,
      to: to,
      state: state,
      deactivated: deactivated,
      activated: activated,
      custom: [
        for (final c in custom)
          if (c['place_of_employment_id'] == null ||
              c['place_of_employment_id'] == placeId)
            c,
      ],
    );
  }

  Future<OvertimeSummary?> _overtime(String userId) async {
    final row = await _tm('overtime_balance')
        .select('date, total_balance')
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return OvertimeSummary(
      minutes: (row['total_balance'] as num).round(),
      asOf: parseWall(row['date'] as String),
    );
  }
}
