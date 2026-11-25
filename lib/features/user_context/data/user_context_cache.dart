import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/user_context.dart';

/// Device cache for [UserContext]. Holds no tokens; cleared on sign-out.
class UserContextCache {
  UserContextCache(this._prefs);

  static const key = 'bamsenet.user_context';
  final SharedPreferencesAsync _prefs;

  Future<UserContext?> read(String userId) async {
    final raw = await _prefs.getString(key);
    if (raw == null) return null;
    try {
      final ctx = UserContext.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      // Never hand one user's cached rights to another account.
      return ctx.userId == userId ? ctx : null;
    } on Object {
      await clear();
      return null;
    }
  }

  Future<void> write(UserContext ctx) =>
      _prefs.setString(key, jsonEncode(ctx.toJson()));

  Future<void> clear() => _prefs.remove(key);
}
