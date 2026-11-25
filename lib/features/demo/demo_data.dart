import '../times/domain/german_time.dart';
import '../times/domain/time_rules.dart';
import '../times/model/overview_data.dart';
import '../times/model/records.dart';

export '../times/model/overview_data.dart';
export '../times/model/records.dart';

// Sample data so the tabs can be seen before the real data screens exist.
// Generated around "today", never sent anywhere. Shown with a
// "Beispieldaten" badge and switched off under Mehr.

class DemoColleagueAbsence {
  const DemoColleagueAbsence({
    required this.name,
    required this.from,
    required this.to,
    this.type,
  });

  final String name;

  /// Null: the company shows presence only ("abwesend").
  final AbsenceType? type;
  final DateTime from;
  final DateTime to;

  String get initials =>
      name.split(' ').where((p) => p.isNotEmpty).map((p) => p[0]).join();
}

enum NotificationKind { missingEntry, approved, rejected, request }

class DemoNotification {
  const DemoNotification({
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    this.unread = false,
  });

  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime at;
  final bool unread;
}

class DemoBalances {
  const DemoBalances({
    required this.entitlement,
    required this.taken,
    required this.planned,
    required this.pending,
    required this.carryOver,
    required this.carryOverExpiry,
    required this.overtimeMinutes,
    required this.overtimeAsOf,
  });

  final double entitlement;
  final double taken;

  /// Approved, still ahead.
  final double planned;
  final double pending;
  final double carryOver;
  final DateTime carryOverExpiry;
  final int overtimeMinutes;
  final DateTime overtimeAsOf;

  /// BR-14: entitlement minus used plus carry-over, pending shown as used.
  double get available => entitlement + carryOver - taken - planned - pending;
}

class DemoData extends OverviewData {
  DemoData._({
    required super.today,
    required super.entries,
    required super.holidays,
    required super.absences,
    required this.colleagues,
    required this.notifications,
    required this.balances,
  }) : super(
         rules: demoRules,
         overtime: OvertimeSummary(
           minutes: balances.overtimeMinutes,
           asOf: balances.overtimeAsOf,
         ),
       );

  static const demoRules = TimeRules(
    minBreakPieceMinutes: 15,
    minRestHours: 11,
  );

  final List<DemoColleagueAbsence> colleagues;
  final List<DemoNotification> notifications;
  final DemoBalances balances;

  int get unreadCount => notifications.where((n) => n.unread).length;

  /// Saxony, where the company is (Dresden).
  static final _saxony2026 = {
    DateTime.utc(2025, 12, 25): '1. Weihnachtstag',
    DateTime.utc(2025, 12, 26): '2. Weihnachtstag',
    DateTime.utc(2026, 1, 1): 'Neujahr',
    DateTime.utc(2026, 4, 3): 'Karfreitag',
    DateTime.utc(2026, 4, 6): 'Ostermontag',
    DateTime.utc(2026, 5, 1): 'Tag der Arbeit',
    DateTime.utc(2026, 5, 14): 'Christi Himmelfahrt',
    DateTime.utc(2026, 5, 25): 'Pfingstmontag',
    DateTime.utc(2026, 10, 3): 'Tag der Deutschen Einheit',
    DateTime.utc(2026, 10, 31): 'Reformationstag',
    DateTime.utc(2026, 11, 18): 'Buß- und Bettag',
    DateTime.utc(2026, 12, 25): '1. Weihnachtstag',
    DateTime.utc(2026, 12, 26): '2. Weihnachtstag',
    DateTime.utc(2027, 1, 1): 'Neujahr',
  };

  static const projects = [
    ProjectRef('2024-017', 'Neubau Kita Sonnenschein'),
    ProjectRef('2024-022', 'Sanierung Rathaus Pirna'),
    ProjectRef('2025-003', 'Wartung Heizung Wohnpark Elbblick'),
    ProjectRef('2025-011', 'Büro und Verwaltung'),
  ];

  static DemoData generate(DateTime now) {
    final today = GermanTime.startOfDay(now);
    DateTime day(int offset) => GermanTime.addDays(today, offset);
    DateTime at(DateTime d, int h, [int m = 0]) =>
        DateTime.utc(d.year, d.month, d.day, h, m);
    final monday = day(-(today.weekday - 1));

    // A week of holiday four weeks ago, Monday to Friday.
    final vacationStart = GermanTime.addDays(monday, -28);
    final vacationEnd = GermanTime.addDays(vacationStart, 4);
    final sickDay = GermanTime.addDays(monday, -40);

    final absences = <AbsenceRecord>[
      AbsenceRecord(
        type: AbsenceType.vacation,
        from: vacationStart,
        to: vacationEnd,
        days: 5,
        status: RequestStatus.approved,
        note: 'Herbstferien',
      ),
      AbsenceRecord(
        type: AbsenceType.sick,
        from: sickDay,
        to: sickDay,
        days: 1,
        status: RequestStatus.approved,
      ),
      AbsenceRecord(
        type: AbsenceType.vacation,
        from: GermanTime.addDays(monday, 14 + 2),
        to: GermanTime.addDays(monday, 14 + 4),
        days: 3,
        status: RequestStatus.pending,
      ),
      AbsenceRecord(
        type: AbsenceType.vacation,
        from: GermanTime.addDays(monday, 35),
        to: GermanTime.addDays(monday, 39),
        days: 5,
        status: RequestStatus.approved,
        note: 'Winterurlaub',
      ),
      AbsenceRecord(
        type: AbsenceType.overtime,
        from: GermanTime.addDays(monday, 7 + 4),
        to: GermanTime.addDays(monday, 7 + 4),
        days: 0.5,
        status: RequestStatus.approved,
        note: 'Freitag Nachmittag',
        firstDayAfternoonOnly: true,
      ),
      AbsenceRecord(
        type: AbsenceType.training,
        from: GermanTime.addDays(monday, -14 + 2),
        to: GermanTime.addDays(monday, -14 + 2),
        days: 1,
        status: RequestStatus.rejected,
        note: 'Seminar Arbeitssicherheit',
      ),
    ];

    final holidays = {
      for (final h in _saxony2026.entries)
        if (!h.key.isAfter(day(60)) && !h.key.isBefore(day(-90)))
          h.key: h.value,
    };

    bool absent(DateTime d) => absences.any(
      (a) =>
          a.status == RequestStatus.approved &&
          a.type != AbsenceType.overtime &&
          a.covers(d),
    );

    final entries = <TimeRecord>[];
    var n = 0;
    TimeRecord entry(
      DateTime d,
      (int, int) from,
      (int, int) to,
      int brk, {
      int project = 0,
      String activity = 'Montage',
      DelayStatus delay = DelayStatus.none,
      WorkPlace? workPlace,
      String? remarks,
      bool nextDay = false,
    }) {
      final end = nextDay ? GermanTime.addDays(d, 1) : d;
      final monthAgo = d.isBefore(DateTime.utc(today.year, today.month, 1));
      final twoMonthsAgo = d.isBefore(
        DateTime.utc(today.year, today.month - 1, 1),
      );
      return TimeRecord(
        id: 'demo-${n++}',
        project: projects[project],
        activity: activity,
        time: TimeEntry(
          start: at(d, from.$1, from.$2),
          end: at(end, to.$1, to.$2),
          breakMinutes: brk,
        ),
        status: twoMonthsAgo
            ? EntryStatus.invoiced
            : monthAgo
            ? EntryStatus.closed
            : EntryStatus.open,
        delay: delay,
        workPlace: workPlace,
        remarks: remarks,
        createdInApp: n.isEven,
      );
    }

    for (var offset = -75; offset <= 0; offset++) {
      final d = day(offset);
      final weekend = d.weekday >= DateTime.saturday;
      if (holidays.containsKey(d) || absent(d)) continue;
      // Yesterday is left empty: the "missing entry" case.
      if (offset == -1 && !weekend) continue;
      if (weekend) {
        // One Saturday morning two weeks ago.
        if (offset >= -15 && offset <= -9 && d.weekday == DateTime.saturday) {
          entries.add(
            entry(
              d,
              (8, 0),
              (12, 0),
              0,
              project: 2,
              activity: 'Störungsdienst',
              remarks: 'Heizungsausfall Haus B',
            ),
          );
        }
        continue;
      }
      if (offset == 0) {
        // Today: a morning so far.
        entries.add(
          entry(d, (7, 0), (11, 30), 0, project: 0, workPlace: WorkPlace.away),
        );
        continue;
      }
      final variant = (offset.abs() * 7) % 6;
      switch (variant) {
        case 0:
          // Split day: gap counts as break.
          entries
            ..add(entry(d, (7, 0), (11, 30), 0, project: 0))
            ..add(
              entry(
                d,
                (12, 0),
                (16, 0),
                0,
                project: 1,
                activity: 'Elektroinstallation',
              ),
            );
        case 1:
          entries.add(
            entry(
              d,
              (6, 30),
              (15, 0),
              30,
              project: 1,
              activity: 'Elektroinstallation',
            ),
          );
        case 2:
          // Long day with too little break: a compliance warning.
          entries.add(
            entry(
              d,
              (6, 0),
              (16, 0),
              30,
              project: 0,
              remarks: 'Betonage, durchgearbeitet',
            ),
          );
        case 3:
          entries.add(
            entry(
              d,
              (8, 0),
              (16, 30),
              30,
              project: 3,
              activity: 'Planung',
              workPlace: WorkPlace.home,
            ),
          );
        case 4:
          entries
            ..add(
              entry(d, (7, 30), (12, 0), 0, project: 2, activity: 'Wartung'),
            )
            ..add(
              entry(d, (12, 45), (16, 15), 0, project: 2, activity: 'Wartung'),
            );
        default:
          entries.add(entry(d, (7, 0), (14, 30), 30, project: 0));
      }
    }

    // A night shift last Thursday.
    final lastThursday = GermanTime.addDays(monday, -4);
    entries
      ..removeWhere((e) => e.day == lastThursday)
      ..add(
        entry(
          lastThursday,
          (18, 0),
          (2, 30),
          30,
          project: 1,
          activity: 'Elektroinstallation',
          remarks: 'Umschluss Netz, nachts',
          nextDay: true,
        ),
      );

    // Late entries: one waiting for approval, one rejected.
    final lastTuesday = GermanTime.addDays(monday, -6);
    entries
      ..removeWhere((e) => e.day == lastTuesday)
      ..add(
        entry(
          lastTuesday,
          (7, 0),
          (15, 30),
          30,
          project: 0,
          delay: DelayStatus.pending,
          remarks: 'Nachgetragen',
        ),
      );
    final threeWeeksAgo = GermanTime.addDays(monday, -19);
    entries
      ..removeWhere((e) => e.day == threeWeeksAgo)
      ..add(
        entry(
          threeWeeksAgo,
          (7, 0),
          (15, 0),
          30,
          project: 3,
          delay: DelayStatus.rejected,
          remarks: 'Zu spät nachgetragen',
        ),
      );

    final colleagues = [
      DemoColleagueAbsence(
        name: 'Jonas Weber',
        type: AbsenceType.vacation,
        from: day(2),
        to: day(6),
      ),
      DemoColleagueAbsence(name: 'Lea Hoffmann', from: day(1), to: day(1)),
      DemoColleagueAbsence(
        name: 'Mehmet Yılmaz',
        type: AbsenceType.training,
        from: day(8),
        to: day(9),
      ),
      DemoColleagueAbsence(
        name: 'Sophie Krause',
        type: AbsenceType.vacation,
        from: day(15),
        to: day(19),
      ),
    ];

    final pending = absences
        .where(
          (a) =>
              a.status == RequestStatus.pending &&
              a.type == AbsenceType.vacation,
        )
        .fold(0.0, (s, a) => s + a.days);
    final planned = absences
        .where(
          (a) =>
              a.status == RequestStatus.approved &&
              a.type == AbsenceType.vacation &&
              a.from.isAfter(today),
        )
        .fold(0.0, (s, a) => s + a.days);

    return DemoData._(
      today: today,
      entries: entries,
      holidays: holidays,
      absences: absences,
      colleagues: colleagues,
      balances: DemoBalances(
        entitlement: 30,
        taken: 17,
        planned: planned,
        pending: pending,
        carryOver: 2,
        carryOverExpiry: DateTime.utc(today.year + 1, 3, 31),
        overtimeMinutes: 750,
        overtimeAsOf: day(-1),
      ),
      notifications: [
        DemoNotification(
          kind: NotificationKind.missingEntry,
          title: 'Zeiteintrag fehlt',
          body: 'Für gestern ist noch keine Arbeitszeit erfasst.',
          at: at(today, 7),
          unread: true,
        ),
        DemoNotification(
          kind: NotificationKind.approved,
          title: 'Urlaub genehmigt',
          body: 'Dein Winterurlaub (5 Tage) wurde genehmigt.',
          at: at(day(-2), 14, 12),
          unread: true,
        ),
        DemoNotification(
          kind: NotificationKind.rejected,
          title: 'Weiterbildung abgelehnt',
          body: 'Seminar Arbeitssicherheit: Bitte im nächsten Quartal neu beantragen.',
          at: at(day(-12), 9, 40),
        ),
        DemoNotification(
          kind: NotificationKind.request,
          title: 'Neuer Antrag',
          body: 'Jonas Weber hat Urlaub beantragt.',
          at: at(day(-15), 16, 5),
        ),
      ],
    );
  }
}
