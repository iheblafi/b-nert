import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend.dart';
import '../../../core/errors/app_failure.dart';
import '../../auth/state/session.dart';
import '../../demo/demo_data.dart';
import '../../demo/demo_mode.dart';

class ProjectOption {
  const ProjectOption({
    required this.id,
    required this.number,
    required this.name,
  });

  final String id;
  final String number;
  final String name;

  String get label => number.isEmpty ? name : '$number · $name';
}

class NamedOption {
  const NamedOption(this.id, this.name, {this.projectId});

  final String id;
  final String name;

  /// For sub-projects: the project they belong to.
  final String? projectId;
}

/// What the form's pickers offer.
class EntryOptions {
  const EntryOptions({
    required this.projects,
    this.subprojects = const [],
    this.activities = const [],
  });

  final List<ProjectOption> projects;
  final List<NamedOption> subprojects;
  final List<NamedOption> activities;

  List<NamedOption> subprojectsOf(String? projectId) => [
    for (final s in subprojects)
      if (s.projectId == projectId) s,
  ];
}

abstract interface class EntryOptionsRepository {
  /// Read only. Throws [AppFailure].
  Future<EntryOptions> load(String userId);
}

class SupabaseEntryOptionsRepository implements EntryOptionsRepository {
  SupabaseEntryOptionsRepository(this._client);

  final SupabaseClient _client;

  PostgrestQueryBuilder<dynamic> _tm(String table) =>
      _client.schema('time_management').from(table);

  @override
  Future<EntryOptions> load(String userId) async {
    try {
      // Future.wait rethrows the first error as is, so a lost connection
      // is reported as such.
      final rows = await Future.wait([
        _tm('project')
            .select('id, project_number, name, protected, manager')
            .eq('active', true)
            .order('project_number'),
        _tm('project_allowed_users').select('project_id').eq('user_id', userId),
        _tm('project_deputy').select('project_id').eq('user_id', userId),
        _tm('subproject')
            .select('id, name, project_id')
            .eq('active', true)
            .order('name'),
        _tm('user_has_activity')
            .select('activity(id, name, active)')
            .eq('user_id', userId),
      ]);
      final [projects, allowed, deputy, subprojects, activities] = rows;
      return entryOptionsFromRows(
        userId: userId,
        projects: projects,
        allowedProjectIds: {
          for (final r in [...allowed, ...deputy]) r['project_id'] as String,
        },
        subprojects: subprojects,
        activities: activities,
      );
    } on Object catch (e) {
      throw AppFailure.from(e);
    }
  }
}

/// Protected projects only for allowed users, deputies and the manager.
/// The backend checks again on save (user_has_project_access).
EntryOptions entryOptionsFromRows({
  required String userId,
  required List<Map<String, dynamic>> projects,
  required Set<String> allowedProjectIds,
  required List<Map<String, dynamic>> subprojects,
  required List<Map<String, dynamic>> activities,
}) => EntryOptions(
  projects: [
    for (final p in projects)
      if (p['protected'] != true ||
          p['manager'] == userId ||
          allowedProjectIds.contains(p['id']))
        ProjectOption(
          id: p['id'] as String,
          number: (p['project_number'] as String?) ?? '',
          name: (p['name'] as String?) ?? '',
        ),
  ],
  subprojects: [
    for (final s in subprojects)
      NamedOption(
        s['id'] as String,
        s['name'] as String,
        projectId: s['project_id'] as String?,
      ),
  ],
  activities: [
    for (final r in activities)
      if (r['activity']
          case {
            'id': final String id,
            'name': final String name,
            'active': final Object? active,
          }
          when active != false)
        NamedOption(id, name),
  ]..sort((a, b) => a.name.compareTo(b.name)),
);

/// Sample options while sample data is on.
EntryOptions demoEntryOptions() => EntryOptions(
  projects: [
    for (final p in DemoData.projects)
      ProjectOption(id: 'demo-${p.number}', number: p.number, name: p.name),
  ],
  subprojects: const [
    NamedOption('demo-sub-1', 'Bauabschnitt 1', projectId: 'demo-2024-017'),
    NamedOption('demo-sub-2', 'Bauabschnitt 2', projectId: 'demo-2024-017'),
  ],
  activities: [
    for (final (i, a) in const [
      'Elektroinstallation',
      'Montage',
      'Planung',
      'Störungsdienst',
      'Wartung',
    ].indexed)
      NamedOption('demo-act-$i', a),
  ],
);

final entryOptionsRepositoryProvider = Provider<EntryOptionsRepository>(
  (ref) => SupabaseEntryOptionsRepository(ref.watch(supabaseClientProvider)),
);

final entryOptionsProvider = FutureProvider<EntryOptions>((ref) async {
  if (ref.watch(demoModeProvider)) return demoEntryOptions();
  final userId = ref.watch(
    sessionProvider.select((s) => s is SignedIn ? s.user.id : null),
  );
  if (userId == null) throw StateError('Not signed in');
  return ref.watch(entryOptionsRepositoryProvider).load(userId);
});
