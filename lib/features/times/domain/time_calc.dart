import 'dart:math' as math;

import 'german_time.dart';
import 'time_rules.dart';

// Ported from the web app's own calculation (its client bundle, modules
// "breakCalculationAlgorithm" and the entry form), so phone and web show
// the same numbers. Rules and examples: docs/research/web-calculation-rules.md.
// All times are German wall clock; see GermanTime.

class EntryTotals {
  const EntryTotals({
    required this.total,
    required this.working,
    required this.night,
    required this.sunday,
    required this.holiday,
  });

  /// End minus start, real minutes.
  final int total;

  /// Total minus the entered break.
  final int working;
  final int night;
  final int sunday;
  final int holiday;
}

/// Minutes of one entry, as the web form fills them in.
/// [holidays]: public and company holidays that apply to the entry.
EntryTotals entryTotals(
  TimeEntry entry,
  TimeRules rules, {
  List<DateTime> holidays = const [],
}) {
  final start = GermanTime.wall(entry.start);
  final end = GermanTime.wall(entry.end);
  final total = math.max<int>(0, GermanTime.minutesBetween(start, end));
  final working = math.max<int>(0, total - entry.breakMinutes);

  final night = math.min<int>(_nightMinutes(start, end, rules), working);

  final holidayDays = holidays.map(GermanTime.startOfDay).toList();
  final (sunday, holiday) = _surcharges(
    start,
    end,
    total,
    entry.breakMinutes,
    holidayDays,
    rules.sundayHolidayRule,
  );

  return EntryTotals(
    total: total,
    working: working,
    night: night,
    sunday: math.min<int>(sunday, working),
    holiday: holidayDays.isEmpty ? 0 : math.min<int>(holiday, working),
  );
}

// --- Night -------------------------------------------------------------

int _nightMinutes(DateTime start, DateTime end, TimeRules rules) {
  final ns = rules.nightStart;
  final ne = rules.nightEnd;
  final day = GermanTime.startOfDay(start);
  final crossesMidnight = ns.hour * 60 + ns.minute > ne.hour * 60 + ne.minute;
  if (!crossesMidnight) {
    // Not covered by the web app's formula (it assumes 22:00 to 06:00 style
    // windows); counted plainly per day. Listed as a client question.
    var sum = 0;
    for (var d = day; !d.isAfter(end); d = GermanTime.addDays(d, 1)) {
      sum += _overlap(
        start,
        end,
        GermanTime.atTime(d, ns.hour, ns.minute),
        GermanTime.atTime(d, ne.hour, ne.minute),
      );
    }
    return sum;
  }
  // The web's formula: the early-morning part of the start day, plus the
  // window from the start day's night start to the next day's night end.
  final earlyEnd = GermanTime.atTime(day, ne.hour, ne.minute);
  final lateStart = GermanTime.atTime(day, ns.hour, ns.minute);
  final lateEnd = GermanTime.atTime(
    GermanTime.addDays(day, 1),
    ne.hour,
    ne.minute,
  );
  var early = 0;
  if (_before(start, earlyEnd)) {
    early = GermanTime.minutesBetween(start, _min(earlyEnd, end));
  }
  final from = _max(start, lateStart);
  final to = _min(end, lateEnd);
  return early + math.max<int>(0, GermanTime.minutesBetween(from, to));
}

// --- Sunday and holiday ------------------------------------------------

typedef _Span = ({DateTime from, DateTime to});

/// Required break for [minutes] of work (statutory bands), as the web
/// uses it for the surcharge share.
int _bandBreak(int minutes) => minutes > 540
    ? 45
    : minutes > 360
    ? 30
    : 0;

/// Each listed day from 00:00 to 24:00, running on to 04:00 the next
/// morning when the entry started before that midnight (§ 3b EStG);
/// clipped to the entry and merged.
List<_Span> _dayWindows(DateTime start, DateTime end, List<DateTime> days) {
  final sorted = [...days]..sort();
  final out = <_Span>[];
  for (final d in sorted) {
    final next = GermanTime.addDays(d, 1);
    final until = _before(start, next)
        ? next.add(const Duration(hours: 4))
        : next;
    final from = _max(d, start);
    final to = _min(until, end);
    if (!_before(from, to)) continue;
    if (out.isNotEmpty && !_before(out.last.to, from)) {
      out[out.length - 1] = (from: out.last.from, to: _max(out.last.to, to));
    } else {
      out.add((from: from, to: to));
    }
  }
  return out;
}

int _sum(List<_Span> spans) =>
    spans.fold<int>(0, (s, w) => s + GermanTime.minutesBetween(w.from, w.to));

List<_Span> _subtract(List<_Span> spans, List<_Span> cut) => cut.fold(
  spans,
  (acc, c) => [
    for (final s in acc)
      if (!_before(c.from, s.to) || !_before(s.from, c.to))
        s
      else ...[
        if (_before(s.from, c.from)) (from: s.from, to: c.from),
        if (_before(c.to, s.to)) (from: c.to, to: s.to),
      ],
  ],
);

List<DateTime> _sundays(DateTime start, DateTime end) {
  if (!_before(start, end)) return const [];
  return [
    for (
      var d = GermanTime.startOfDay(start);
      !d.isAfter(GermanTime.startOfDay(end));
      d = GermanTime.addDays(d, 1)
    )
      if (d.weekday == DateTime.sunday) d,
  ];
}

/// Minutes in the windows, minus the share of the break the law expects
/// to fall inside them.
int _withBreakShare(int inWindows, int total, int breakMinutes) {
  if (inWindows == 0) return 0;
  final share = _bandBreak(inWindows);
  final extra = math.max<int>(
    0,
    breakMinutes - share - math.max<int>(0, total - inWindows),
  );
  return math.max<int>(0, inWindows - share - extra);
}

(int sunday, int holiday) _surcharges(
  DateTime start,
  DateTime end,
  int total,
  int breakMinutes,
  List<DateTime> holidays,
  SundayHolidayRule rule,
) {
  final sundays = _sundays(start, end);
  if (rule == SundayHolidayRule.both) {
    final sunday = _withBreakShare(
      _sum(_dayWindows(start, end, sundays)),
      total,
      breakMinutes,
    );
    final holiday = holidays.isEmpty
        ? 0
        : _withBreakShare(
            _sum(_dayWindows(start, end, holidays)),
            total,
            breakMinutes,
          );
    return (sunday, holiday);
  }

  // Holiday only: Sunday windows lose the holiday parts. The break is
  // taken off the larger kind first: first each kind's own legal share,
  // then whatever of the break cannot have fallen outside the windows.
  final holidayWindows = _dayWindows(start, end, holidays);
  final sundayWindows = _subtract(
    _dayWindows(start, end, sundays),
    holidayWindows,
  );
  final kinds = [
    _Kind(isHoliday: true, gross: _sum(holidayWindows)),
    _Kind(isHoliday: false, gross: _sum(sundayWindows)),
  ]..sort((a, b) => b.gross.compareTo(a.gross));
  final inWindows = kinds.fold<int>(0, (s, k) => s + k.gross);
  final outside = total - inWindows;
  var left = math.max<int>(_bandBreak(inWindows), breakMinutes - outside);
  for (final k in kinds) {
    k.deducted = [_bandBreak(k.gross), k.gross, left].reduce(math.min);
    left -= k.deducted;
  }
  var rest = math.max<int>(
    0,
    breakMinutes - kinds.fold<int>(0, (s, k) => s + k.deducted) - outside,
  );
  for (final k in kinds) {
    final more = math.min<int>(k.gross - k.deducted, rest);
    k.deducted += more;
    rest -= more;
  }
  final holiday = kinds.firstWhere((k) => k.isHoliday);
  final sunday = kinds.firstWhere((k) => !k.isHoliday);
  return (sunday.gross - sunday.deducted, holiday.gross - holiday.deducted);
}

class _Kind {
  _Kind({required this.isHoliday, required this.gross});
  final bool isHoliday;
  final int gross;
  int deducted = 0;
}

// --- Day check ---------------------------------------------------------

class RestShortfall {
  const RestShortfall({required this.entry, required this.restMinutes});

  /// The entry that starts too soon after the previous work.
  final TimeEntry entry;

  /// The longest rest found in the 24 hours before it.
  final int restMinutes;
}

class DayCheck {
  const DayCheck({
    required this.netWork,
    required this.explicitBreak,
    required this.gapBreak,
    required this.ignoredBreak,
    required this.requiredBreak,
    required this.compliant,
    required this.exceedsMaxWorkingHours,
    required this.restShortfalls,
  });

  /// Work after counted breaks, over all shifts.
  final int netWork;

  /// Entered breaks that count.
  final int explicitBreak;

  /// Gaps between entries that count as break.
  final int gapBreak;

  /// Breaks and gaps below the minimum piece.
  final int ignoredBreak;
  final int requiredBreak;

  /// Every shift has its required break. A warning, never a block (BR-6).
  final bool compliant;
  final bool exceedsMaxWorkingHours;
  final List<RestShortfall> restShortfalls;

  int get totalBreak => explicitBreak + gapBreak;
}

/// Checks [entries] against the break, long-day and rest rules. [day]
/// is the day for the long-day warning (the first entry's by default).
DayCheck checkDay(List<TimeEntry> entries, TimeRules rules, {DateTime? day}) {
  final sorted = [...entries]..sort((a, b) => _wallCompare(a.start, b.start));
  final piece = rules.minBreakPieceMinutes;
  var net = 0, explicit = 0, gaps = 0, ignored = 0, required = 0;
  var compliant = true;
  for (final shift in _shifts(sorted, rules.shiftBoundaryHours)) {
    final n = _netWork(shift, piece);
    final ex = _explicitBreak(shift, piece);
    final gp = _gapBreak(shift, piece);
    final need = rules.breakRule == BreakRule.attendance
        ? _attendanceBreak(_span(shift))
        : _statutoryBreak(n);
    net += n;
    explicit += ex;
    gaps += gp;
    ignored += _explicitBreak(shift, null) + _gapBreak(shift, null) - ex - gp;
    required += need;
    if (ex + gp < need) compliant = false;
  }

  final limit = rules.maxWorkingHoursWarning;
  var longDay = false;
  if (limit != null && sorted.isNotEmpty) {
    final ref = GermanTime.startOfDay(day ?? sorted.first.start);
    final thatDay = sorted.where(
      (x) => GermanTime.startOfDay(GermanTime.wall(x.start)) == ref,
    );
    longDay = _netWork(thatDay.toList(), piece) > limit * 60;
  }

  return DayCheck(
    netWork: net,
    explicitBreak: explicit,
    gapBreak: gaps,
    ignoredBreak: ignored,
    requiredBreak: required,
    compliant: compliant,
    exceedsMaxWorkingHours: longDay,
    restShortfalls: _restShortfalls(sorted, rules.minRestHours),
  );
}

/// A break or gap counts only if positive and at least the minimum piece.
int _counted(int minutes, int? piece) =>
    minutes <= 0 || (piece != null && minutes < piece) ? 0 : minutes;

int _duration(TimeEntry x) => GermanTime.minutesBetween(x.start, x.end);

int _netWork(List<TimeEntry> xs, int? piece) => xs.fold<int>(
  0,
  (s, x) => s + _duration(x) - _counted(x.breakMinutes, piece),
);

int _explicitBreak(List<TimeEntry> xs, int? piece) =>
    xs.fold<int>(0, (s, x) => s + _counted(x.breakMinutes, piece));

int _gapBreak(List<TimeEntry> xs, int? piece) {
  var sum = 0;
  for (var i = 0; i < xs.length - 1; i++) {
    sum += _counted(
      GermanTime.minutesBetween(xs[i].end, xs[i + 1].start),
      piece,
    );
  }
  return sum;
}

/// First start to the last entry's end.
int _span(List<TimeEntry> xs) => xs.isEmpty
    ? 0
    : math.max<int>(0, GermanTime.minutesBetween(xs.first.start, xs.last.end));

int _statutoryBreak(int netWork) => netWork > 540
    ? 45
    : netWork > 360
    ? 30
    : 0;

int _attendanceBreak(int presence) => presence >= 570
    ? 45
    : presence >= 360
    ? 30
    : 0;

/// A new shift starts when an entry begins more than [boundaryHours]
/// after the latest end so far.
List<List<TimeEntry>> _shifts(List<TimeEntry> sorted, int boundaryHours) {
  final shifts = <List<TimeEntry>>[];
  DateTime? latestEnd;
  for (final x in sorted) {
    final start = GermanTime.wall(x.start);
    final end = GermanTime.wall(x.end);
    if (latestEnd == null ||
        GermanTime.minutesBetween(latestEnd, start) > boundaryHours * 60) {
      shifts.add([x]);
      latestEnd = end;
    } else {
      shifts.last.add(x);
      if (_before(latestEnd, end)) latestEnd = end;
    }
  }
  return shifts;
}

/// For each entry, the longest stretch without work in the 24 hours
/// before its start must reach [minRestHours].
List<RestShortfall> _restShortfalls(List<TimeEntry> sorted, int? minRestHours) {
  if (minRestHours == null) return const [];
  final real = sorted
      .where((x) => _before(GermanTime.wall(x.start), GermanTime.wall(x.end)))
      .toList();
  final out = <RestShortfall>[];
  for (final entry in sorted) {
    final start = GermanTime.instant(entry.start);
    final windowStart = start.subtract(const Duration(hours: 24));
    var freeSince = windowStart;
    var longest = 0;
    for (final other in real) {
      if (identical(other, entry)) continue;
      final oStart = GermanTime.instant(other.start);
      final oEnd = GermanTime.instant(other.end);
      if (!oEnd.isAfter(windowStart) || !oStart.isBefore(start)) continue;
      final busyFrom = oStart.isAfter(windowStart) ? oStart : windowStart;
      if (busyFrom.isAfter(freeSince)) {
        longest = math.max<int>(
          longest,
          busyFrom.difference(freeSince).inMinutes,
        );
      }
      final busyTo = oEnd.isBefore(start) ? oEnd : start;
      if (busyTo.isAfter(freeSince)) freeSince = busyTo;
    }
    final last = math.max<int>(0, start.difference(freeSince).inMinutes);
    longest = math.max<int>(longest, last);
    if (longest < minRestHours * 60) {
      out.add(RestShortfall(entry: entry, restMinutes: last));
    }
  }
  return out;
}

// --- Suggested break ---------------------------------------------------

/// The break the form proposes for [entry], given the [others] of the
/// same shift, in 5-minute steps.
int suggestBreak(
  TimeEntry entry,
  TimeRules rules, {
  List<TimeEntry> others = const [],
}) {
  final piece = rules.minBreakPieceMinutes;
  final all = [...others, entry]
    ..sort((a, b) => _wallCompare(a.start, b.start));
  final span = math.max<int>(
    0,
    GermanTime.minutesBetween(all.first.start, all.last.end),
  );
  final needed = rules.breakRule == BreakRule.attendance
      ? _attendanceBreak(span)
      : _smallestStatutoryBreak(span);
  final missing = math.max<int>(
    0,
    needed - _explicitBreak(others, piece) - _gapBreak(all, piece),
  );
  final minimum = missing > 0 ? math.max<int>(missing, piece ?? 0) : 0;
  return 5 * (minimum / 5).ceil();
}

/// The smallest break b for which the work left (span − b) needs no more
/// than b: 9 h 35 of presence needs only 35 min, not 45.
int _smallestStatutoryBreak(int span) {
  const bands = [
    (min: 541, max: null, need: 45),
    (min: 361, max: 540, need: 30),
    (min: 0, max: 360, need: 0),
  ];
  final ok = [
    for (final b in bands)
      math.max<int>(
        0,
        math.max<int>(b.need, b.max == null ? 0 : span - b.max!),
      ),
  ].where((c) => _statutoryBreak(math.max<int>(0, span - c)) <= c);
  return ok.isEmpty ? 45 : ok.reduce(math.min);
}

// --- Helpers -----------------------------------------------------------

bool _before(DateTime a, DateTime b) =>
    GermanTime.instant(a).isBefore(GermanTime.instant(b));

DateTime _min(DateTime a, DateTime b) => _before(b, a) ? b : a;

DateTime _max(DateTime a, DateTime b) => _before(a, b) ? b : a;

int _wallCompare(DateTime a, DateTime b) =>
    GermanTime.instant(a).compareTo(GermanTime.instant(b));

int _overlap(DateTime s, DateTime e, DateTime ws, DateTime we) {
  final from = _max(s, ws);
  final to = _min(e, we);
  return _before(from, to) ? GermanTime.minutesBetween(from, to) : 0;
}
