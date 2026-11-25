import 'package:flutter_mobile/features/user_context/model/company_settings.dart';
import 'package:flutter_mobile/features/user_context/model/user_access.dart';
import 'package:flutter_mobile/features/user_context/model/user_context.dart';

UserContext userContext({
  String userId = 'u1',
  Set<String> roles = const {'user'},
  Map<String, bool> permissions = const {'absencerequest': true},
  bool supervises = false,
  bool licence = true,
  String? firstName = 'Anna',
  CompanySettings settings = const CompanySettings(),
}) => UserContext(
  userId: userId,
  firstName: firstName,
  settings: settings,
  access: UserAccess(
    roles: roles,
    permissions: permissions,
    supervisesSomeone: supervises,
    hasLicence: licence,
  ),
  loadedAt: DateTime.utc(2026, 11, 21),
);
