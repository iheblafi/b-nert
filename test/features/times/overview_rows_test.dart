import 'package:flutter_mobile/features/times/data/overview_rows.dart';
import 'package:flutter_mobile/features/times/model/records.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Shape of a real demo row (docs/research, .tmp/reference), with the
  // embedded project and activity the repository asks for.
  final row = <String, dynamic>{
    'id': 'd3ff75e1',
    'project_id': 'p1',
    'start_date': '2026-10-15T08:30:00',
    'end_date': '2026-10-15T17:00:00',
    'minutes': 510,
    'minutes_break': 30,
    'minutes_working': 480,
    'minutes_feast': 0,
    'minutes_sunday': 0,
    'minutes_night': 0,
    'location': null,
    'remarks': '  ',
    'closed': false,
    'platform_id': 'web',
    'status': 'recorded',
    'delay_status': 'not_delayed',
    'holiday_state': null,
    'work_place': 'home',
    'project': {'id': 'p1', 'project_number': '2025-003', 'name': 'Wartung'},
    'activity': {'name': 'Montage'},
    'subproject': null,
  };

  test('a working_time row', () {
    final e = timeRecordFromRow(row);
    expect(e.time.start, DateTime.utc(2026, 10, 15, 8, 30));
    expect(e.time.end, DateTime.utc(2026, 10, 15, 17));
    expect(e.time.breakMinutes, 30);
    expect(e.stored!.working, 480);
    expect(e.stored!.total, 510);
    expect(e.project.number, '2025-003');
    expect(e.project.id, 'p1');
    expect(e.activity, 'Montage');
    expect(e.subproject, isNull);
    expect(e.remarks, isNull);
    expect(e.workPlace, WorkPlace.home);
    expect(e.status, EntryStatus.open);
    expect(e.delay, DelayStatus.none);
    expect(e.createdInApp, isFalse);
    expect(e.counts, isTrue);
  });

  test('status, delay and platform values', () {
    final e = timeRecordFromRow({
      ...row,
      'status': 'invoiced',
      'delay_status': 'rejected',
      'platform_id': 'app',
      'activity': null,
    });
    expect(e.status, EntryStatus.invoiced);
    expect(e.locked, isTrue);
    expect(e.delay, DelayStatus.rejected);
    expect(e.counts, isFalse);
    expect(e.createdInApp, isTrue);
    expect(e.activity, '');
    expect(
      timeRecordFromRow({...row, 'status': 'recorded', 'closed': true}).status,
      EntryStatus.closed,
    );
  });

  test('parseWall ignores any offset and keeps the wall clock', () {
    expect(parseWall('2026-03-29T02:30:00'), DateTime.utc(2026, 3, 29, 2, 30));
    expect(
      parseWall('2026-03-29T02:30:00+02:00'),
      DateTime.utc(2026, 3, 29, 2, 30),
    );
    expect(parseWall('2026-11-24'), DateTime.utc(2026, 11, 24));
    expect(isoDay(DateTime.utc(2026, 1, 5)), '2026-01-05');
  });

  test('an absence request row', () {
    final a = absenceFromRow({
      'start_date': '2026-11-09',
      'end_date': '2026-11-13',
      'first_day_afternoon_only': false,
      'last_day_morning_only': true,
      'total_working_days': 4.5,
      'hours': null,
      'request_status_type_id': 'approved',
      'remarks': 'Herbst',
      'training_title': null,
      'account_category': {'name': 'vacation'},
    })!;
    expect(a.type, AbsenceType.vacation);
    expect(a.days, 4.5);
    expect(a.shareOn(DateTime.utc(2026, 11, 13)), 0.5);
    expect(a.shareOn(DateTime.utc(2026, 11, 12)), 1);
    expect(a.note, 'Herbst');
    expect(
      absenceFromRow({
        'start_date': '2026-11-09',
        'end_date': '2026-11-09',
        'request_status_type_id': 'approved',
        'hours': 2,
        'account_category': {'name': 'overtime'},
      })!.shareOn(DateTime.utc(2026, 11, 9)),
      0,
      reason: 'hourly overtime reduction keeps the day',
    );
    expect(
      absenceFromRow({
        'start_date': '2026-11-09',
        'end_date': '2026-11-09',
        'request_status_type_id': 'approved',
        'account_category': {'name': 'unknown'},
      }),
      isNull,
    );
  });

  test('work time model rows: hours to minutes, newest period first', () {
    final e = expectedFromRows(
      [
        {
          'work_time_model_id': 'm1',
          'start_date': '2025-01-01',
          'end_date': '2026-06-30',
        },
        {
          'work_time_model_id': 'm2',
          'start_date': '2026-07-01',
          'end_date': null,
        },
      ],
      [
        {
          'id': 'm1',
          'monday_hours': 8,
          'tuesday_hours': 8,
          'wednesday_hours': 8,
          'thursday_hours': 8,
          'friday_hours': 8,
          'saturday_hours': 0,
          'sunday_hours': 0,
        },
        {
          'id': 'm2',
          'monday_hours': 8.5,
          'tuesday_hours': 8.5,
          'wednesday_hours': 8.5,
          'thursday_hours': 8.5,
          'friday_hours': 6,
          'saturday_hours': 0,
          'sunday_hours': 0,
        },
      ],
    );
    expect(e.assumed, isFalse);
    expect(e.baseOn(DateTime.utc(2026, 11, 23)), 510);
    expect(e.baseOn(DateTime.utc(2026, 11, 27)), 360);
    expect(e.baseOn(DateTime.utc(2026, 3, 2)), 480);
    expect(e.baseOn(DateTime.utc(2024, 3, 4)), 0, reason: 'before any model');
  });

  test('place of employment: the one covering the day, else the newest', () {
    final rows = [
      {
        'place_of_employment_id': 'old',
        'start_date': '2024-01-01',
        'end_date': '2025-12-31',
      },
      {
        'place_of_employment_id': 'new',
        'start_date': '2026-01-01',
        'end_date': null,
      },
    ];
    expect(placeOn(rows, DateTime.utc(2025, 5, 1)), 'old');
    expect(placeOn(rows, DateTime.utc(2026, 5, 1)), 'new');
    expect(placeOn(rows, DateTime.utc(2023, 5, 1)), 'new');
    expect(placeOn([], DateTime.utc(2026, 5, 1)), isNull);
  });

  test('holidays: switches per location and company holidays', () {
    final h = holidaysFor(
      from: DateTime.utc(2026, 5, 1),
      to: DateTime.utc(2026, 12, 31),
      state: 'SN',
      deactivated: {'Reformationstag'},
      activated: {'Fronleichnam'},
      custom: [
        {
          'name': 'Heiligabend',
          'date': '2026-12-24',
          'half_day': true,
          'active': true,
        },
        {
          'name': 'Betriebsausflug',
          'date': '2026-07-03',
          'half_day': false,
          'active': false,
        },
        {
          'name': 'Firmenjubiläum',
          'date': '2026-10-03',
          'half_day': true,
          'active': true,
        },
      ],
    );
    expect(h.names[DateTime.utc(2026, 6, 4)], 'Fronleichnam');
    expect(h.names.containsKey(DateTime.utc(2026, 10, 31)), isFalse);
    expect(h.names[DateTime.utc(2026, 12, 24)], 'Heiligabend');
    expect(h.halfDays, {DateTime.utc(2026, 12, 24)});
    expect(h.names.containsKey(DateTime.utc(2026, 7, 3)), isFalse);
    // A half-day company holiday on a public holiday keeps the full day.
    expect(h.names[DateTime.utc(2026, 10, 3)], 'Tag der Deutschen Einheit');
    expect(h.names.containsKey(DateTime.utc(2026, 4, 6)), isFalse);
  });
}
