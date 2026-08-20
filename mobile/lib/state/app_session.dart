import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repository.dart';
import '../models/app_user.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/local_store.dart';
import '../services/session_store.dart';
import '../services/settings_store.dart';

class LoginOutcome {
  final bool success;
  final bool offline;
  final String? error;

  const LoginOutcome({required this.success, this.offline = false, this.error});

  static const ok = LoginOutcome(success: true);
  static const okOffline = LoginOutcome(success: true, offline: true);
  factory LoginOutcome.failure(String message) => LoginOutcome(success: false, error: message);
}

/// Root authentication + app-lifecycle state. Owns the [ApiClient] and
/// [Repository] instances used by every screen, and restores a previous
/// session (including whether it was an offline demo session) on launch.
class AppSession extends ChangeNotifier {
  final SettingsStore settings = SettingsStore();
  final SessionStore sessionStore = SessionStore();
  late final ApiClient api;
  late final Repository repository;

  bool initializing = true;
  bool isAuthenticated = false;
  bool offlineLogin = false;
  AppUser? currentUser;
  String apiBaseUrl = '';

  AppSession() {
    api = ApiClient(baseUrl: SettingsStore.defaultBaseUrl());
    repository = Repository(api: api, local: LocalStore());
  }

  Future<void> initialize() async {
    apiBaseUrl = await settings.getApiBaseUrl();
    api.baseUrl = apiBaseUrl;

    final token = await sessionStore.loadToken();
    final user = await sessionStore.loadUser();
    if (token != null && user != null) {
      api.authToken = token;
      currentUser = user;
      offlineLogin = await sessionStore.wasOfflineLogin();
      isAuthenticated = true;
      unawaited(repository.syncPending());
      unawaited(_tryUpgradeOfflineSession());
    }
    initializing = false;
    notifyListeners();
  }

  /// An offline-demo session is signed in with a fake local identity
  /// (id -1, never validated by the server). If connectivity has since come
  /// back, silently swap in a real demo-login so any *new* records the
  /// officer creates from here on carry a real, syncable user id instead of
  /// staying attributed to the placeholder. Records already made under the
  /// placeholder id are unaffected — this only changes identity going
  /// forward, it does not retroactively rewrite past local records.
  Future<void> _tryUpgradeOfflineSession() async {
    if (!offlineLogin) return;
    try {
      final tokenJson = await api.post('/auth/demo-login') as Map<String, dynamic>;
      final token = tokenJson['access_token'] as String;
      api.authToken = token;
      final meJson = await api.get('/me') as Map<String, dynamic>;
      final user = AppUser.fromJson(meJson);
      await sessionStore.save(token: token, user: user, offline: false);
      currentUser = user;
      offlineLogin = false;
      notifyListeners();
      unawaited(repository.syncPending());
    } on ApiNetworkException {
      // Still offline — keep the local identity, try again next time.
    } on ApiHttpException {
      // Backend reachable but rejected the upgrade; keep the offline identity.
    }
  }

  /// Public hook for "Sync now" — reconnecting should also try to promote
  /// an offline-demo session to a real one, not just flush the write queue.
  Future<void> reconnect() async {
    await _tryUpgradeOfflineSession();
    await repository.syncPending();
  }

  Future<LoginOutcome> login({required String officerId, required String password}) async {
    try {
      final tokenJson = await api.post('/auth/login', body: {
        'officer_id': officerId,
        'password': password,
      }) as Map<String, dynamic>;
      final token = tokenJson['access_token'] as String;
      api.authToken = token;
      final meJson = await api.get('/me') as Map<String, dynamic>;
      final user = AppUser.fromJson(meJson);
      await sessionStore.save(token: token, user: user, offline: false);
      currentUser = user;
      isAuthenticated = true;
      offlineLogin = false;
      notifyListeners();
      unawaited(repository.syncPending());
      return LoginOutcome.ok;
    } on ApiHttpException catch (e) {
      return LoginOutcome.failure(e.message);
    } on ApiNetworkException catch (e) {
      return LoginOutcome.failure('Backend unreachable: ${e.message}. Use Demo Login for offline mode.');
    }
  }

  Future<LoginOutcome> demoLogin() async {
    try {
      final tokenJson = await api.post('/auth/demo-login') as Map<String, dynamic>;
      final token = tokenJson['access_token'] as String;
      api.authToken = token;
      final meJson = await api.get('/me') as Map<String, dynamic>;
      final user = AppUser.fromJson(meJson);
      await sessionStore.save(token: token, user: user, offline: false);
      currentUser = user;
      isAuthenticated = true;
      offlineLogin = false;
      notifyListeners();
      unawaited(repository.syncPending());
      return LoginOutcome.ok;
    } on ApiNetworkException {
      // Backend unreachable: fall back to a fully local offline demo
      // session so the field workflow can still be demonstrated end to end.
      const offlineUser = AppUser(id: -1, officerId: 'DEMO-001', name: 'Demo Officer (Offline)', role: 'field_officer');
      const offlineToken = 'OFFLINE-DEMO-TOKEN';
      api.authToken = offlineToken;
      await sessionStore.save(token: offlineToken, user: offlineUser, offline: true);
      currentUser = offlineUser;
      isAuthenticated = true;
      offlineLogin = true;
      notifyListeners();
      return LoginOutcome.okOffline;
    } on ApiHttpException catch (e) {
      return LoginOutcome.failure(e.message);
    }
  }

  Future<void> logout() async {
    await sessionStore.clear();
    currentUser = null;
    isAuthenticated = false;
    offlineLogin = false;
    api.authToken = null;
    notifyListeners();
  }

  Future<void> updateApiBaseUrl(String url) async {
    await settings.setApiBaseUrl(url);
    apiBaseUrl = await settings.getApiBaseUrl();
    api.baseUrl = apiBaseUrl;
    notifyListeners();
    unawaited(repository.syncPending());
  }
}
