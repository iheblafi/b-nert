import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'secret_store.dart';

/// Keeps the Supabase session (access and refresh token) in the keystore
/// instead of the package default, shared preferences (spec F1, AC6).
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage(this._store);

  static const sessionKey = 'bamsenet.session';

  final SecretStore _store;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => await _store.read(sessionKey) != null;

  @override
  Future<String?> accessToken() => _store.read(sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _store.write(sessionKey, persistSessionString);

  @override
  Future<void> removePersistedSession() => _store.delete(sessionKey);

  /// Only for diagnostics: whether a stored session looks well-formed.
  Future<bool> hasValidShape() async {
    final raw = await _store.read(sessionKey);
    if (raw == null) return false;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> &&
          decoded['refresh_token'] != null;
    } on FormatException {
      return false;
    }
  }
}
