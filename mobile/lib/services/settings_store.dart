import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Persists user-configurable app settings, notably the FastAPI backend
/// base URL. Field devices connect over varied networks (emulator, LAN,
/// hotspot, browser), so this must be editable at runtime rather than
/// hard-coded. Uses `defaultTargetPlatform` instead of `dart:io`'s
/// `Platform` because `dart:io` does not exist on the web compile target.
class SettingsStore {
  static const _apiBaseUrlKey = 'settings.api_base_url';

  static String defaultBaseUrl() {
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  Future<String> getApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiBaseUrlKey) ?? defaultBaseUrl();
  }

  Future<void> setApiBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    await prefs.setString(_apiBaseUrlKey, trimmed.isEmpty ? defaultBaseUrl() : trimmed);
  }
}
