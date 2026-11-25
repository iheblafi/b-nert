/// Build-time configuration, passed with `--dart-define` or
/// `--dart-define-from-file=config/<env>.json`. Nothing secret is committed.
class AppConfig {
  const AppConfig({required this.supabaseUrl, required this.supabaseAnonKey});

  factory AppConfig.fromEnvironment() => const AppConfig(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final String supabaseUrl;
  final String supabaseAnonKey;

  /// False when the app was built without a backend, e.g. in tests or CI.
  bool get hasBackend => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
