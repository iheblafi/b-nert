/// What the signed-in user may see. The app never hard-codes roles to
/// features; it decides from permissions and relations (spec section 3).
class UserAccess {
  const UserAccess({
    required this.roles,
    required this.permissions,
    required this.supervisesSomeone,
    required this.hasLicence,
  });

  factory UserAccess.fromJson(Map<String, dynamic> j) => UserAccess(
    roles: {...(j['roles'] as List<dynamic>).cast<String>()},
    permissions: (j['permissions'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as bool),
    ),
    supervisesSomeone: j['supervises_someone'] as bool,
    hasLicence: j['has_licence'] as bool,
  );

  /// Role names from time_management.role, e.g. user, project_manager.
  final Set<String> roles;

  /// Permission id -> true for write access, false for read only.
  final Map<String, bool> permissions;

  final bool supervisesSomeone;
  final bool hasLicence;

  /// False leads to the "Kein Zugriff" screen (spec F1, AC3).
  bool get hasTimeTracking => hasLicence && roles.isNotEmpty;

  bool get canApproveAbsences =>
      permissions.containsKey('absencerequests') || supervisesSomeone;

  bool get canApproveLateEntries => permissions['approveDelays'] ?? false;

  bool get seesApprovals => canApproveAbsences || canApproveLateEntries;

  Map<String, dynamic> toJson() => {
    'roles': roles.toList()..sort(),
    'permissions': permissions,
    'supervises_someone': supervisesSomeone,
    'has_licence': hasLicence,
  };
}
