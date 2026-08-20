import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

/// Persists the logged-in officer's auth token and profile locally so the
/// app can resume a session without re-authenticating on every launch.
class SessionStore {
  static const _tokenKey = 'session.token';
  static const _userKey = 'session.user';
  static const _offlineKey = 'session.offline';

  Future<void> save({required String token, required AppUser user, bool offline = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setBool(_offlineKey, offline);
  }

  Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<AppUser?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> wasOfflineLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_offlineKey) ?? false;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_offlineKey);
  }
}
