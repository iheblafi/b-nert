import '../domain/german_time.dart';
import '../domain/time_calc.dart';
import '../domain/time_rules.dart';

/// Entry status in the backend (working_time.status).
enum EntryStatus { open, closed, invoiced }

/// Late-entry state (working_time.delay_status).
enum DelayStatus { none, pending, approved, rejected }

/// Absence type (account_category.name).
enum AbsenceType { vacation, sick, overtime, training, special }

/// Request state (account_request.request_status_type_id).
enum RequestStatus { pending, approved, rejected, cancelled }

/// How a day looks in the overview (F2).
enum DayStatus {
  complete,
  incomplete,
  missing,
  absent,
  holiday,
  weekend,
  future,
}

/// Work place on an entry (working_time.work_place).
enum WorkPlace { office, home, away }

class ProjectRef {
  const ProjectRef(this.number, this.name, {this.id});

  final String? id;
  final String number;
  final String name;
}

/// One time entry as the overview shows it, from the backend or sample data.
class TimeRecord {
  const TimeRecord({
    required this.id,
    required this.project,
    required this.activity,
    required this.time,
    this.status = EntryStatus.open,
    this.delay = DelayStatus.none,
    this.workPlace,
    this.subproject,
    this.location,
    this.holidayState,
    this.remarks,
    this.createdInApp = false,
    this.stored,
  });

  final String id;
  final ProjectRef project;

  /// Empty when no activity is set.
  final String activity;
  final TimeEntry time;
  final EntryStatus status;
  final DelayStatus delay;

  final WorkPlace? workPlace;
  final String? subproject;
  final String? location;
  final String? holidayState;
  final String? remarks;
  final bool createdInApp;

  /// Minutes the backend stored for the entry. The backend is the
  /// authority for saved entries (docs/adr/0002), so these win over the
  /// app's own calculation when present.
  final EntryTotals? stored;

  DateTime get day => GermanTime.startOfDay(time.start);

  /// Late entries waiting or rejected do not count (BR-10).
  bool get counts => delay == DelayStatus.none || delay == DelayStatus.approved;

  bool get locked => status != EntryStatus.open;

  EntryTotals totals(TimeRules rules) => stored ?? entryTotals(time, rules);
}

class AbsenceRecord {
  const AbsenceRecord({
    required this.type,
    required this.from,
    required this.to,
    required this.days,
    required this.status,
    this.note,
    this.firstDayAfternoonOnly = false,
    this.lastDayMorningOnly = false,
    this.hourly = false,
  });

  final AbsenceType type;
  final DateTime from;
  final DateTime to;
  final double days;
  final RequestStatus status;
  final String? note;
  final bool firstDayAfternoonOnly;
  final bool lastDayMorningOnly;

  /// Hourly overtime reduction: does not free the whole day.
  final bool hourly;

  bool covers(DateTime day) => !day.isBefore(from) && !day.isAfter(to);

  /// Share of [day] the absence takes: 1, 0.5 or 0.
  double shareOn(DateTime day) {
    if (hourly || !covers(day)) return 0;
    final first = day == from && firstDayAfternoonOnly;
    final last = day == to && lastDayMorningOnly;
    return first || last ? 0.5 : 1;
  }
}

class OvertimeSummary {
  const OvertimeSummary({required this.minutes, required this.asOf});

  final int minutes;
  final DateTime asOf;
}
