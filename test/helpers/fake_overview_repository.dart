import 'package:flutter_mobile/features/time_entry/data/entry_options_repository.dart';
import 'package:flutter_mobile/features/times/data/overview_repository.dart';
import 'package:flutter_mobile/features/times/model/overview_data.dart';
import 'package:flutter_mobile/features/times/model/records.dart';
import 'package:flutter_mobile/features/user_context/model/company_settings.dart';

/// Backend overview in tests: [entries] and [absences] are returned for
/// every range; [result] set to an error makes the load fail.
class FakeOverviewRepository implements OverviewRepository {
  FakeOverviewRepository({
    this.entries = const [],
    this.absences = const [],
    this.holidays = const {},
  });

  List<TimeRecord> entries;
  List<AbsenceRecord> absences;
  Map<DateTime, String> holidays;
  Object? result;
  final loads = <(DateTime, DateTime)>[];

  @override
  Future<OverviewData> load({
    required String userId,
    required DateTime from,
    required DateTime to,
    required DateTime today,
    required CompanySettings settings,
  }) async {
    loads.add((from, to));
    if (result case final Object e) throw e;
    return OverviewData(
      today: today,
      rules: settings.timeRules,
      entries: entries,
      holidays: holidays,
      absences: absences,
      from: from,
      to: to,
      loadedAt: DateTime.utc(2026, 11, 24, 9),
    );
  }
}

class FakeEntryOptionsRepository implements EntryOptionsRepository {
  FakeEntryOptionsRepository([EntryOptions? options])
    : options =
          options ??
          const EntryOptions(
            projects: [
              ProjectOption(id: 'p1', number: '2025-001', name: 'Rathaus'),
              ProjectOption(id: 'p2', number: '2025-002', name: 'Kita'),
            ],
            subprojects: [NamedOption('s1', 'Abschnitt A', projectId: 'p1')],
            activities: [NamedOption('a1', 'Montage')],
          );

  final EntryOptions options;

  @override
  Future<EntryOptions> load(String userId) async => options;
}
