/// German wall-clock time (Europe/Berlin) without a time zone database.
///
/// Entries are stored as wall-clock time (BR-18). Durations must count
/// the clock change like the web app does (it runs in a German browser):
/// 01:00 to 04:00 on the last Sunday of October is 4 hours. The EU rule is
/// fixed: summer time from 01:00 UTC on the last Sunday of March to 01:00
/// UTC on the last Sunday of October.
abstract final class GermanTime {
  /// The wall-clock fields of [t], whatever zone the DateTime carries.
  static DateTime wall(DateTime t) =>
      DateTime.utc(t.year, t.month, t.day, t.hour, t.minute);

  /// The real instant (UTC) of a German wall-clock time. In the autumn
  /// hour that happens twice, the first one (summer time) is taken; in the
  /// spring hour that does not exist, winter time is assumed. Both match
  /// how browsers read such times, so phone and web agree.
  static DateTime instant(DateTime wallClock) {
    final w = wall(wallClock);
    final summer = w.subtract(const Duration(hours: 2));
    return _isSummer(summer) ? summer : w.subtract(const Duration(hours: 1));
  }

  /// The German wall-clock time at [moment] (any zone; read as an instant).
  static DateTime fromInstant(DateTime moment) {
    final utc = moment.toUtc();
    final w = utc.add(Duration(hours: _isSummer(utc) ? 2 : 1));
    return DateTime.utc(w.year, w.month, w.day, w.hour, w.minute);
  }

  /// Real minutes from [a] to [b], both wall-clock times.
  static int minutesBetween(DateTime a, DateTime b) =>
      instant(b).difference(instant(a)).inMinutes;

  static bool _isSummer(DateTime utc) {
    final y = utc.year;
    final from = DateTime.utc(y, 3, _lastSunday(y, 3), 1);
    final to = DateTime.utc(y, 10, _lastSunday(y, 10), 1);
    return !utc.isBefore(from) && utc.isBefore(to);
  }

  static int _lastSunday(int year, int month) {
    final last = DateTime.utc(year, month + 1, 0);
    return last.day - (last.weekday % 7);
  }

  /// Midnight of the day of [t], wall clock.
  static DateTime startOfDay(DateTime t) =>
      DateTime.utc(t.year, t.month, t.day);

  /// Same wall-clock time [days] later (calendar days, not 24 h blocks).
  static DateTime addDays(DateTime t, int days) =>
      DateTime.utc(t.year, t.month, t.day + days, t.hour, t.minute);

  static DateTime atTime(DateTime day, int hour, int minute) =>
      DateTime.utc(day.year, day.month, day.day, hour, minute);
}
