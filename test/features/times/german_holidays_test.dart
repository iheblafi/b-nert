import 'package:flutter_mobile/features/times/domain/german_holidays.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _days(int year, String state) => [
  for (final h in publicHolidays(year, state))
    if (!h.regional) h.date.toIso8601String().substring(0, 10),
];

void main() {
  test('Easter Sunday', () {
    expect(easterSunday(2025), DateTime.utc(2025, 4, 20));
    expect(easterSunday(2026), DateTime.utc(2026, 4, 5));
    expect(easterSunday(2027), DateTime.utc(2027, 3, 28));
  });

  // The web's list for the demo user (Saxony), from the stage page payload.
  test('Saxony 2026 and 2027 match the web exactly', () {
    expect(
      [..._days(2026, 'SN'), ..._days(2027, 'SN')],
      [
        '2026-01-01', '2026-04-03', '2026-04-06', '2026-05-01', //
        '2026-05-14', '2026-05-25', '2026-10-03', '2026-10-31',
        '2026-11-18', '2026-12-25', '2026-12-26',
        '2027-01-01', '2027-03-26', '2027-03-29', '2027-05-01',
        '2027-05-06', '2027-05-17', '2027-10-03', '2027-10-31',
        '2027-11-17', '2027-12-25', '2027-12-26',
      ],
    );
  });

  test('Fronleichnam is regional in Saxony, statewide in Bavaria', () {
    final sn = publicHolidays(
      2026,
      'SN',
    ).firstWhere((h) => h.name == 'Fronleichnam');
    expect(sn.regional, isTrue);
    expect(sn.date, DateTime.utc(2026, 6, 4));
    final by = publicHolidays(2026, 'BY');
    expect(by.firstWhere((h) => h.name == 'Fronleichnam').regional, isFalse);
    expect(by.map((h) => h.name), contains('Allerheiligen'));
    expect(by.map((h) => h.name), isNot(contains('Reformationstag')));
  });

  test('state-specific days', () {
    expect(_days(2026, 'BE'), contains('2026-03-08'));
    expect(_days(2026, 'TH'), contains('2026-09-20'));
    expect(_days(2026, 'NI'), contains('2026-10-31'));
    expect(_days(2026, 'BW'), contains('2026-01-06'));
    expect(_days(2026, 'HE'), isNot(contains('2026-01-06')));
    // Buß- und Bettag only in Saxony.
    expect(_days(2026, 'BY'), isNot(contains('2026-11-18')));
    // Every state has the nine nationwide days.
    for (final s in federalStates) {
      expect(_days(2026, s).length, greaterThanOrEqualTo(9), reason: s);
    }
  });
}
