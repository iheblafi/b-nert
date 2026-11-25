import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../model/company_settings.dart';
import '../model/user_access.dart';
import '../model/user_context.dart';

abstract interface class UserContextRepository {
  /// Loads settings and access from the backend. Throws [AppFailure].
  Future<UserContext> load(String userId);
}

class SupabaseUserContextRepository implements UserContextRepository {
  SupabaseUserContextRepository(this._client, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Licence id of the time-tracking product in tenant.license.
  static const timeTrackingLicence = 'zeiterfassung-standard';

  final SupabaseClient _client;
  final DateTime Function() _now;

  PostgrestQueryBuilder<dynamic> _tm(String table) =>
      _client.schema('time_management').from(table);

  @override
  Future<UserContext> load(String userId) async {
    try {
      final (setting, roleRows, supervises, licence, person) = await (
        _tm('setting').select().limit(1).maybeSingle(),
        _tm('user_owns_role')
            .select('role_id, role(name)')
            .eq('user_id', userId),
        _supervises(userId),
        _hasLicence(userId),
        _name(userId),
      ).wait;
      final roleIds = roleRows.map((r) => r['role_id'] as String).toList();
      final roles = {
        for (final r in roleRows)
          if ((r['role'] as Map<String, dynamic>?)?['name'] case final String n)
            n,
      };

      final permissions = <String, bool>{};
      if (roleIds.isNotEmpty) {
        final rows = await _tm('role_has_permission')
            .select('permission_id, write_access')
            .inFilter('role_id', roleIds);
        for (final row in rows) {
          final id = row['permission_id'] as String;
          final write = row['write_access'] as bool? ?? false;
          permissions[id] = (permissions[id] ?? false) || write;
        }
      }

      return UserContext(
        userId: userId,
        settings: setting == null
            ? const CompanySettings()
            : CompanySettings.fromJson(setting),
        access: UserAccess(
          roles: roles,
          permissions: permissions,
          supervisesSomeone: supervises,
          hasLicence: licence,
        ),
        loadedAt: _now(),
        firstName: person?['first_name'] as String?,
        lastName: person?['last_name'] as String?,
      );
    } on Object catch (e) {
      throw AppFailure.from(e);
    }
  }

  /// Name for the greeting. Optional: a failure must not block sign-in.
  Future<Map<String, dynamic>?> _name(String userId) async {
    try {
      return await _client
          .schema('tenant')
          .from('user')
          .select('first_name, last_name')
          .eq('id', userId)
          .maybeSingle();
    } on Object {
      return null;
    }
  }

  Future<bool> _supervises(String userId) async {
    final today = _now().toIso8601String().substring(0, 10);
    final rows = await _tm('user_supervisor')
        .select('user_id')
        .eq('supervisor_id', userId)
        .or('end_date.is.null,end_date.gte.$today')
        .limit(1);
    return rows.isNotEmpty;
  }

  // UNVERIFIED: the columns of tenant.tenant_owns_license were not read
  // during the analysis. Check them against the stage OpenAPI document
  // before release; until then a failing query counts as "has licence"
  // so a schema mismatch cannot lock every user out.
  Future<bool> _hasLicence(String userId) async {
    try {
      final rows = await _client
          .schema('tenant')
          .from('tenant_owns_license')
          .select('license_id')
          .eq('license_id', timeTrackingLicence)
          .limit(1);
      return rows.isNotEmpty;
    } on PostgrestException {
      return true;
    }
  }
}
