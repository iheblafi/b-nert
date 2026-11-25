/// German public holidays by federal state, computed (no backend call).
///
/// The web asks a server action for these (getHolidayDatesForState); the
/// app cannot call it, so it uses the fixed list of the 16 state laws.
/// Holidays that apply only in some communities of a state are marked
/// [PublicHoliday.regional]; the web leaves them out unless the company
/// activates them for a location (official_holiday_activated). Checked
/// against the web's list for Saxony 2026 and 2027.
library;

class PublicHoliday {
  const PublicHoliday(this.date, this.name, {this.regional = false});

  /// Midnight UTC of the day, like the other wall-clock dates in the app.
  final DateTime date;
  final String name;
  final bool regional;
}

const federalStates = [
  'BW', 'BY', 'BE', 'BB', 'HB', 'HH', 'HE', 'MV', //
  'NI', 'NW', 'RP', 'SL', 'SN', 'ST', 'SH', 'TH',
];

/// Easter Sunday (Gregorian, anonymous algorithm).
DateTime easterSunday(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = (h + l - 7 * m + 114) % 31 + 1;
  return DateTime.utc(year, month, day);
}

/// All holidays of [state] in [year], sorted by date. Unknown state codes
/// get the nine nationwide holidays.
List<PublicHoliday> publicHolidays(int year, String state) {
  final easter = easterSunday(year);
  DateTime e(int days) =>
      DateTime.utc(easter.year, easter.month, easter.day + days);
  DateTime d(int month, int day) => DateTime.utc(year, month, day);
  bool any(List<String> states) => states.contains(state);

  // Buß- und Bettag: the Wednesday before 23 November.
  final nov22 = d(11, 22);
  final repentance = DateTime.utc(
    year,
    11,
    22 - (nov22.weekday - DateTime.wednesday) % 7,
  );

  final out = <PublicHoliday>[
    PublicHoliday(d(1, 1), 'Neujahr'),
    if (any(['BW', 'BY', 'ST'])) PublicHoliday(d(1, 6), 'Heilige Drei Könige'),
    if (state == 'BE' && year >= 2019 || state == 'MV' && year >= 2023)
      PublicHoliday(d(3, 8), 'Internationaler Frauentag'),
    PublicHoliday(e(-2), 'Karfreitag'),
    if (state == 'BB') PublicHoliday(easter, 'Ostersonntag'),
    PublicHoliday(e(1), 'Ostermontag'),
    PublicHoliday(d(5, 1), 'Tag der Arbeit'),
    PublicHoliday(e(39), 'Christi Himmelfahrt'),
    if (state == 'BB') PublicHoliday(e(49), 'Pfingstsonntag'),
    PublicHoliday(e(50), 'Pfingstmontag'),
    if (any(['BW', 'BY', 'HE', 'NW', 'RP', 'SL']))
      PublicHoliday(e(60), 'Fronleichnam')
    else if (any(['SN', 'TH']))
      PublicHoliday(e(60), 'Fronleichnam', regional: true),
    if (state == 'BY')
      PublicHoliday(d(8, 8), 'Augsburger Friedensfest', regional: true),
    if (state == 'SL')
      PublicHoliday(d(8, 15), 'Mariä Himmelfahrt')
    else if (state == 'BY')
      PublicHoliday(d(8, 15), 'Mariä Himmelfahrt', regional: true),
    if (state == 'TH' && year >= 2019) PublicHoliday(d(9, 20), 'Weltkindertag'),
    PublicHoliday(d(10, 3), 'Tag der Deutschen Einheit'),
    if (any(['BB', 'MV', 'SN', 'ST', 'TH']) ||
        year >= 2018 && any(['HB', 'HH', 'NI', 'SH']))
      PublicHoliday(d(10, 31), 'Reformationstag'),
    if (any(['BW', 'BY', 'NW', 'RP', 'SL']))
      PublicHoliday(d(11, 1), 'Allerheiligen'),
    if (state == 'SN') PublicHoliday(repentance, 'Buß- und Bettag'),
    PublicHoliday(d(12, 25), '1. Weihnachtstag'),
    PublicHoliday(d(12, 26), '2. Weihnachtstag'),
  ]..sort((a, b) => a.date.compareTo(b.date));
  return out;
}
