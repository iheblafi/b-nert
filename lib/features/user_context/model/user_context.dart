import 'company_settings.dart';
import 'user_access.dart';

/// Everything loaded once after sign-in and cached on the device.
class UserContext {
  const UserContext({
    required this.userId,
    required this.settings,
    required this.access,
    required this.loadedAt,
    this.firstName,
    this.lastName,
  });

  factory UserContext.fromJson(Map<String, dynamic> j) => UserContext(
    userId: j['user_id'] as String,
    settings: CompanySettings.fromJson(j['settings'] as Map<String, dynamic>),
    access: UserAccess.fromJson(j['access'] as Map<String, dynamic>),
    loadedAt: DateTime.parse(j['loaded_at'] as String),
    firstName: j['first_name'] as String?,
    lastName: j['last_name'] as String?,
  );

  final String userId;
  final CompanySettings settings;
  final UserAccess access;
  final DateTime loadedAt;

  /// From tenant.user; null when not set or not readable.
  final String? firstName;
  final String? lastName;

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'settings': settings.toJson(),
    'access': access.toJson(),
    'loaded_at': loadedAt.toUtc().toIso8601String(),
    'first_name': firstName,
    'last_name': lastName,
  };
}
