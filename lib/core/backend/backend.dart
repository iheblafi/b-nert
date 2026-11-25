import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../session/secret_store.dart';
import '../session/secure_session_storage.dart';

/// Connects to the Supabase backend. Call once in main before runApp.
/// Token refresh runs inside the client (autoRefreshToken).
Future<SupabaseClient> initBackend(
  AppConfig config, {
  SecretStore? store,
}) async {
  final supabase = await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSessionStorage(store ?? KeystoreSecretStore()),
    ),
    debug: false,
  );
  return supabase.client;
}

/// The backend client. Overridden in main (real) and in tests (fake).
/// Only repositories may read it; screens never do.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => throw StateError('supabaseClientProvider not overridden'),
);
