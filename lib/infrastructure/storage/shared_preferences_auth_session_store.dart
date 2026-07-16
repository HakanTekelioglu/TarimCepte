import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth/auth_session_store.dart';

class SharedPreferencesAuthSessionStore implements AuthSessionStore {
  static const String _localUserKey = 'current_user';
  static const String _supabaseUserIdKey = 'supabase_session_user_id';
  static const String _rememberMeKey = 'auth_remember_me';
  static const String _lastActivityKey = 'auth_last_activity_at';

  @override
  Future<String?> readLocalUserJson() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_localUserKey);
  }

  @override
  Future<void> writeLocalUserJson(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localUserKey, value);
  }

  @override
  Future<String?> readSupabaseUserId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_supabaseUserIdKey);
  }

  @override
  Future<void> writeSupabaseUserId(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_supabaseUserIdKey, value);
  }

  @override
  Future<bool> isRememberMeEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_rememberMeKey) ?? false;
  }

  @override
  Future<String?> readLastActivity() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_lastActivityKey);
  }

  @override
  Future<void> configureRememberMe(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_rememberMeKey, enabled);

    if (enabled) {
      await preferences.setString(
        _lastActivityKey,
        DateTime.now().toUtc().toIso8601String(),
      );
    } else {
      await preferences.remove(_lastActivityKey);
    }
  }

  @override
  Future<void> markActive() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _lastActivityKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_localUserKey);
    await preferences.remove(_supabaseUserIdKey);
    await preferences.remove(_rememberMeKey);
    await preferences.remove(_lastActivityKey);
  }
}
