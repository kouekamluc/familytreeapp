import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'local_storage_service.dart';
import 'credential_storage.dart';
import 'edit_drafts.dart';
import 'mutation_ticket.dart';
import '../models/family_tree.dart';
import '../models/heritage_key.dart';
import '../models/person.dart';
import '../models/relationship.dart';
import '../models/user.dart';

class ApiService extends ChangeNotifier {
  String get _storagePrefix => base64Url.encode(utf8.encode(ApiConfig.baseUrl));
  String get _sessionKey => 'session_v3_$_storagePrefix';
  String get _tokenKey => 'session_v2_${_storagePrefix}_token';
  String get _refreshKey => 'session_v2_${_storagePrefix}_refresh';
  String get _userKey => 'session_v2_${_storagePrefix}_user';
  String? _sessionServer;
  int _sessionVersion = 0;
  Future<bool>? _refreshing;
  String? lastError;
  bool lastRevisionConflict = false;
  int pendingFamilyRequests = 0, pendingFamilyReviews = 0;
  String get identity =>
      '${ApiConfig.baseUrl}:${_isPreviewMode ? "preview" : currentUser?.id}';
  String? get cacheScope => currentUser == null || _isPreviewMode
      ? null
      : 'v2_${base64Url.encode(utf8.encode(ApiConfig.baseUrl))}_${currentUser!.id}';

  String? _token;
  String? _refreshToken;
  User? _currentUser;
  bool _isPreviewMode = false;

  String? get token => _token;
  User? get currentUser => _sessionServer == ApiConfig.baseUrl || _isPreviewMode
      ? _currentUser
      : null;
  bool get isAuthenticated =>
      _isPreviewMode ||
      (_sessionServer == ApiConfig.baseUrl &&
          _token != null &&
          _currentUser != null);
  bool get isPreviewMode => _isPreviewMode;

  Future<void> init() async {
    await ApiConfig.init();
    _sessionServer = ApiConfig.baseUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Old sessions have no trustworthy server binding: require a fresh login.
      for (final key in [
        'auth_token',
        'auth_refresh',
        'auth_user',
        'saved_accounts_list',
        'active_account_username',
      ]) {
        await prefs.remove(key);
      }
      final credentials = CredentialStorage();
      final session = await credentials.read(_sessionKey);
      Map<String, dynamic> saved;
      if (session != null) {
        saved = jsonDecode(session) as Map<String, dynamic>;
      } else {
        final oldUser = await credentials.read(_userKey);
        saved = {
          'token': await credentials.read(_tokenKey),
          'refresh': await credentials.read(_refreshKey),
          'user': oldUser == null ? null : jsonDecode(oldUser),
        };
        await credentials.write(_sessionKey, jsonEncode(saved));
      }
      for (final key in [_tokenKey, _refreshKey, _userKey]) {
        await credentials.write(key, null);
      }
      _token = saved['token'];
      _refreshToken = saved['refresh'];
      final userStr = saved['user'] == null ? null : jsonEncode(saved['user']);
      if (_token == 'demo_token') {
        _token = null;
        _refreshToken = null;
        await credentials.write(_sessionKey, null);
      }
      if (_token != null && userStr != null) {
        _currentUser = User.fromJson(jsonDecode(userStr));
        // Re-write legacy user metadata without a reusable personal-key secret.
        await _persistSession();
        await LocalStorageService().setActiveAccount(_currentUser!.username);
      }
    } catch (e) {
      debugPrint('Error initializing auth storage: $e');
    }
  }

  Future<void> probeBackend() async {
    // Network discovery must not delay the first rendered frame.
    for (final base in ApiConfig.candidateUrls) {
      try {
        final res = await http
            .get(Uri.parse('$base/health/'))
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200 &&
            jsonDecode(res.body)['service'] == 'familytree') {
          ApiConfig.setBaseUrl(base);
          debugPrint('Connected to backend at $base');
          break;
        }
      } catch (_) {
        // Continue to next candidate
      }
    }
  }

  Map<String, String> _headers({bool requiresAuth = true}) {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth &&
        _sessionServer == ApiConfig.baseUrl &&
        _token != null &&
        _token!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_token';
    }
    return map;
  }

  Future<void> _persistSession() async {
    final version = _sessionVersion;
    final server = ApiConfig.baseUrl;
    final key = _sessionKey;
    final user = _currentUser;
    final access = _token;
    final refresh = _refreshToken;
    await CredentialStorage().write(
      key,
      access == null
          ? null
          : jsonEncode({
              'token': access,
              'refresh': refresh,
              'user': user?.toJson(),
            }),
    );
    if (version != _sessionVersion || server != ApiConfig.baseUrl) return;
    if (user != null && access != null) {
      await LocalStorageService().saveAccount(
        SavedAccount(
          userId: user.id,
          serverUrl: server,
          username: user.username,
          displayName: user.displayName,
          token: access,
          refreshToken: refresh,
        ),
      );
    }
  }

  Future<bool> _tryRefreshToken(String origin) {
    if (_refreshing != null) return _refreshing!;
    final version = _sessionVersion;
    final server = ApiConfig.baseUrl;
    final refreshToken = _refreshToken;
    if (refreshToken == null || _sessionServer != server) {
      return Future.value(false);
    }
    final future = (() async {
      try {
        final response = await http
            .post(
              Uri.parse('$server${ApiConfig.tokenRefreshEndpoint}'),
              headers: _headers(requiresAuth: false),
              body: jsonEncode({'refresh': refreshToken}),
            )
            .timeout(const Duration(seconds: 8));
        if (version != _sessionVersion || server != ApiConfig.baseUrl) {
          return false;
        }
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _token = data['access'];
          _refreshToken = data['refresh'] ?? refreshToken;
          await _persistSession();
          return true;
        }
        if (response.statusCode == 401 || response.statusCode == 400) {
          await _clearSession();
        }
      } catch (_) {
        /* Network failure retains the same identity's offline snapshot. */
      }
      return false;
    })();
    _refreshing = future;
    future.whenComplete(() {
      if (identical(_refreshing, future)) _refreshing = null;
    });
    return future;
  }

  void _recordError(http.Response response) {
    if (response.statusCode < 400) return;
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      lastRevisionConflict =
          response.statusCode == 409 &&
          data is Map &&
          data['code'] == 'stale_revision';
      lastError = data is Map
          ? data.entries
                .where((e) => !['code', 'error_code'].contains(e.key))
                .map(
                  (e) =>
                      '${e.value is List ? (e.value as List).join("\n") : e.value}',
                )
                .join('\n')
          : '$data';
    } catch (_) {
      lastError = 'Request failed (${response.statusCode}).';
    }
  }

  Future<http.Response> _request(
    String method,
    Uri url, {
    Object? body,
    Map<String, String>? extraHeaders,
  }) async {
    final version = _sessionVersion;
    final server = ApiConfig.baseUrl;
    if (url.origin != Uri.parse(server).origin) {
      throw StateError('Unexpected API server.');
    }
    lastError = null;
    lastRevisionConflict = false;
    Future<http.Response> send() {
      final headers = _headers()..addAll(extraHeaders ?? {});
      return switch (method) {
        'GET' => http.get(url, headers: headers),
        'POST' => http.post(url, headers: headers, body: body),
        'PATCH' => http.patch(url, headers: headers, body: body),
        'DELETE' => http.delete(url, headers: headers),
        _ => throw ArgumentError(method),
      };
    }

    late http.Response response;
    try {
      response = await send().timeout(const Duration(seconds: 12));
    } catch (_) {
      lastError = 'Connection interrupted. Check the server and try again.';
      rethrow;
    }
    if (version != _sessionVersion || server != ApiConfig.baseUrl) {
      throw StateError('Session changed.');
    }
    if (response.statusCode == 401 && await _tryRefreshToken(url.origin)) {
      if (version != _sessionVersion) throw StateError('Session changed.');
      response = await send().timeout(const Duration(seconds: 12));
    }
    if (version != _sessionVersion || server != ApiConfig.baseUrl) {
      throw StateError('Session changed.');
    }
    _recordError(response);
    return response;
  }

  Future<http.Response> _getWithAuth(Uri url) => _request('GET', url);
  Future<http.Response> _postWithAuth(
    Uri url, {
    Object? body,
    Map<String, String>? extraHeaders,
  }) => _request('POST', url, body: body, extraHeaders: extraHeaders);
  Future<http.Response> _patchWithAuth(Uri url, {Object? body}) =>
      _request('PATCH', url, body: body);
  Future<http.Response> _deleteWithAuth(Uri url) => _request('DELETE', url);

  Future<void> _clearSession() async {
    final formerIdentity =
        '${_sessionServer ?? ApiConfig.baseUrl}:${_isPreviewMode ? "preview" : _currentUser?.id}';
    _sessionVersion++;
    pendingFamilyRequests = pendingFamilyReviews = 0;
    _token = null;
    _refreshToken = null;
    _currentUser = null;
    _isPreviewMode = false;
    lastInvitedTreeId = null;
    lastInvitedPersonId = null;
    lastInvitedTreeName = null;
    await EditDrafts.clearAccount(formerIdentity);
    await MutationTicket.clearAccount(formerIdentity);
    await _persistSession();
    await LocalStorageService().setActiveAccount(null);
    notifyListeners();
  }

  // --- AUTHENTICATION ---

  Future<bool> login(String username, String password) async {
    lastAuthError = null;
    for (final base in ApiConfig.candidateUrls) {
      final url = Uri.parse('$base${ApiConfig.tokenEndpoint}');
      try {
        final response = await http
            .post(
              url,
              headers: _headers(requiresAuth: false),
              body: jsonEncode({'username': username, 'password': password}),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          _sessionVersion++;
          pendingFamilyRequests = pendingFamilyReviews = 0;
          _sessionServer = base;
          _isPreviewMode = false;
          _currentUser = null;
          ApiConfig.setBaseUrl(base);
          final data = jsonDecode(response.body);
          _currentUser = null;
          _token = data['access'];
          _refreshToken = data['refresh'];

          await fetchCurrentUser();
          if (_currentUser == null) {
            await _clearSession();
            return false;
          }
          if (_currentUser != null) {
            await LocalStorageService().saveAccount(
              SavedAccount(
                userId: _currentUser!.id,
                username: _currentUser!.username,
                displayName: _currentUser!.displayName,
                token: _token,
                refreshToken: _refreshToken,
                role: _currentUser!.isStaff ? 'CURATOR' : 'FAMILY_MEMBER',
              ),
            );
          }
          await _persistSession();
          notifyListeners();
          return _currentUser != null;
        } else {
          _recordError(response);
          lastAuthError = lastError;
        }
      } catch (e) {
        debugPrint('Login exception on $base: $e');
      }
    }
    lastAuthError ??= 'Unable to reach the server. Check your connection.';
    return false;
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? passwordConfirmation,
  }) async {
    lastAuthError = null;
    for (final base in ApiConfig.candidateUrls) {
      final url = Uri.parse('$base/auth/register/');
      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'username': username,
                'email': email,
                'password': password,
                'password2': passwordConfirmation ?? password,
                if (firstName != null && firstName.isNotEmpty)
                  'first_name': firstName,
                if (lastName != null && lastName.isNotEmpty)
                  'last_name': lastName,
              }),
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 201 || response.statusCode == 200) {
          ApiConfig.setBaseUrl(base);
          // Auto-login upon successful registration
          return await login(username, password);
        } else {
          try {
            final data = jsonDecode(utf8.decode(response.bodyBytes));
            if (data is Map) {
              final msgs = <String>[];
              data.forEach((k, v) {
                if (v is List && v.isNotEmpty) {
                  msgs.add('$k: ${v.first}');
                } else if (v is String) {
                  msgs.add(v);
                }
              });
              if (msgs.isNotEmpty) lastAuthError = msgs.join('\n');
            }
          } catch (_) {
            lastAuthError = 'Registration failed (${response.statusCode})';
          }
        }
      } catch (e) {
        debugPrint('Registration exception on $base: $e');
      }
    }
    lastAuthError ??= 'Unable to reach the registration server.';
    return false;
  }

  String? lastAuthError;

  int? lastInvitedTreeId;
  int? lastInvitedPersonId;
  String? lastInvitedTreeName;

  Future<bool> loginWithHeritageKey(String heritageKey) async {
    final cleanKey = heritageKey.trim().toUpperCase();
    lastAuthError = null;

    for (final base in ApiConfig.candidateUrls) {
      final url = Uri.parse('$base${ApiConfig.heritageKeyLoginEndpoint}');
      try {
        final response = await http
            .post(
              url,
              headers: _headers(requiresAuth: false),
              body: jsonEncode({'heritage_key': cleanKey}),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          _sessionVersion++;
          pendingFamilyRequests = pendingFamilyReviews = 0;
          _sessionServer = base;
          _isPreviewMode = false;
          ApiConfig.setBaseUrl(base);
          final data = jsonDecode(response.body);
          _currentUser = null;
          _token = data['access'];
          _refreshToken = data['refresh'];

          if (data['family_tree'] != null &&
              data['family_tree']['id'] != null) {
            lastInvitedTreeId = data['family_tree']['id'] as int;
            lastInvitedTreeName = data['family_tree']['name']?.toString();
          } else {
            lastInvitedTreeId = null;
            lastInvitedTreeName = null;
          }

          if (data['person_id'] != null) {
            lastInvitedPersonId = data['person_id'] as int;
          } else {
            lastInvitedPersonId = null;
          }

          if (data['user'] != null) {
            _currentUser = User.fromJson(data['user']);
          } else {
            await fetchCurrentUser();
          }

          if (_currentUser != null) {
            await LocalStorageService().saveAccount(
              SavedAccount(
                userId: _currentUser!.id,
                username: _currentUser!.username,
                displayName: _currentUser!.displayName,
                token: _token,
                refreshToken: _refreshToken,
                role: 'FAMILY_MEMBER',
              ),
            );
          }
          if (_currentUser == null) {
            await _clearSession();
            return false;
          }
          await _persistSession();
          notifyListeners();
          return true;
        } else if (response.statusCode == 400 ||
            response.statusCode == 401 ||
            response.statusCode == 403) {
          try {
            final data = jsonDecode(response.body);
            lastAuthError =
                data['error']?.toString() ??
                data['detail']?.toString() ??
                (data['errors'] != null
                    ? data['errors'].toString()
                    : 'This personal key is invalid or inactive.');
          } catch (_) {
            lastAuthError = 'This personal key is invalid or expired.';
          }
          return false;
        }
      } catch (e) {
        debugPrint('Heritage Key Login exception on $base: $e');
      }
    }

    lastAuthError ??= 'Connection unavailable. Try again when you are online.';
    return false;
  }

  Future<void> demoLogin() async {
    _sessionVersion++;
    pendingFamilyRequests = pendingFamilyReviews = 0;
    _isPreviewMode = true;
    notifyListeners();
    _token = null;
    _refreshToken = null;
    _currentUser = User(
      id: 0,
      username: 'preview',
      email: '',
      firstName: 'Explore',
      lastName: '',
      isStaff: false,
    );
    await CredentialStorage().write(_sessionKey, null);
    lastInvitedTreeId = null;
    lastInvitedPersonId = null;
    await LocalStorageService().setActiveAccount(null);
    notifyListeners();
  }

  Future<void> logout() async {
    final server = _sessionServer;
    final access = _token;
    final refresh = _refreshToken;
    final username = _currentUser?.username;
    await _clearSession();
    if (username != null) await LocalStorageService().removeAccount(username);
    if (refresh != null && server == ApiConfig.baseUrl) {
      try {
        await http
            .post(
              Uri.parse('$server/auth/logout/'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $access',
              },
              body: jsonEncode({'refresh': refresh}),
            )
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        /* Local logout completes even when revocation cannot reach the server. */
      }
    }
  }

  Future<bool> switchToAccount(SavedAccount account) async {
    if (account.serverUrl != ApiConfig.baseUrl || account.token == null) {
      return false;
    }
    final version = ++_sessionVersion;
    final server = ApiConfig.baseUrl;
    try {
      var access = account.token!;
      var refresh = account.refreshToken;
      var response = await http
          .get(
            Uri.parse('$server/users/me/'),
            headers: {'Authorization': 'Bearer $access'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 401 && refresh != null) {
        final renewed = await http
            .post(
              Uri.parse('$server${ApiConfig.tokenRefreshEndpoint}'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refresh': refresh}),
            )
            .timeout(const Duration(seconds: 8));
        if (renewed.statusCode == 200) {
          final data = jsonDecode(renewed.body);
          access = data['access'];
          refresh = data['refresh'] ?? refresh;
          response = await http
              .get(
                Uri.parse('$server/users/me/'),
                headers: {'Authorization': 'Bearer $access'},
              )
              .timeout(const Duration(seconds: 8));
        }
      }
      if (response.statusCode != 200 ||
          version != _sessionVersion ||
          server != ApiConfig.baseUrl) {
        return false;
      }
      final user = User.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      if (user.id != account.userId) return false;
      _token = access;
      _refreshToken = refresh;
      _currentUser = user;
      _sessionServer = server;
      _isPreviewMode = false;
      lastInvitedTreeId = null;
      lastInvitedPersonId = null;
      lastInvitedTreeName = null;
      await _persistSession();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<User?> fetchCurrentUser() async {
    if (_isPreviewMode) return _currentUser;
    if (_token == null) return null;
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users/me/');
      final res = await _getWithAuth(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        _currentUser = User.fromJson(data);
        await _persistSession();
        return _currentUser;
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        await _clearSession();
        return null;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  // --- HERITAGE KEYS ---

  Future<List<HeritageKey>> getHeritageKeys() async {
    if (_isPreviewMode) return [];
    for (final base in ApiConfig.candidateUrls) {
      final url = Uri.parse('$base${ApiConfig.heritageKeysMeEndpoint}');
      try {
        final res = await _getWithAuth(url);
        if (res.statusCode == 200) {
          ApiConfig.setBaseUrl(base);
          final List data = jsonDecode(utf8.decode(res.bodyBytes));
          return data.map((item) => HeritageKey.fromJson(item)).toList();
        }
      } catch (e) {
        debugPrint('Error getting heritage keys from $base: $e');
      }
    }
    throw Exception('Unable to load your keys. Check your connection.');
  }

  Future<HeritageKey?> generateHeritageKey({
    String name = 'Personal key',
    String role = 'FAMILY_MEMBER',
  }) async {
    if (_isPreviewMode) return null;
    for (final base in ApiConfig.candidateUrls) {
      final url = Uri.parse('$base${ApiConfig.heritageKeyGenerateEndpoint}');
      try {
        final res = await _postWithAuth(
          url,
          body: jsonEncode({'name': name, 'role': role}),
        );
        if (res.statusCode == 201 || res.statusCode == 200) {
          ApiConfig.setBaseUrl(base);
          return HeritageKey.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
        }
      } catch (e) {
        debugPrint('Error generating heritage key on $base: $e');
      }
    }
    return null;
  }

  Future<bool> revokeHeritageKey(int keyId) async {
    if (_isPreviewMode) return false;
    for (final base in ApiConfig.candidateUrls) {
      final url = Uri.parse('$base${ApiConfig.heritageKeyRevokeEndpoint}');
      try {
        final res = await _postWithAuth(
          url,
          body: jsonEncode({'key_id': keyId}),
        );
        if (res.statusCode == 200) {
          ApiConfig.setBaseUrl(base);
          return true;
        }
      } catch (e) {
        debugPrint('Error revoking heritage key on $base: $e');
      }
    }
    return false;
  }

  Future<List<dynamic>> _getList(Uri url) async {
    final results = <dynamic>[];
    final visited = <String>{};
    Uri? page = url;
    while (page != null) {
      if (page.origin != url.origin || !visited.add(page.toString())) {
        throw StateError('Invalid pagination link.');
      }
      final response = await _getWithAuth(page);
      if (response.statusCode != 200) {
        throw StateError(lastError ?? 'Unable to load records.');
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is List) {
        results.addAll(data);
        break;
      }
      if (data is! Map || data['results'] is! List) {
        throw const FormatException('Invalid list response.');
      }
      results.addAll(data['results'] as List);
      page = data['next'] == null
          ? null
          : page.resolve(data['next'].toString());
    }
    return results;
  }

  void _accountError(http.Response response) {
    if (response.statusCode < 400) return;
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 429) {
        lastError = 'Too many attempts. Wait a minute and try again.';
      } else if (data is Map && data.containsKey('new_password')) {
        lastError = 'Choose a stronger password.';
      } else {
        final message = data is Map ? data.values.first : data;
        lastError = message is List
            ? message.first.toString()
            : message.toString();
      }
    } catch (_) {
      lastError = 'Unable to complete this action.';
    }
  }

  Future<Map<String, dynamic>?> accountDetails() async {
    return _accountCall('GET', 'account/', {});
  }

  Future<Map<String, dynamic>?> accountAction(Map<String, dynamic> data) async {
    return _accountCall('POST', 'account/', data);
  }

  Future<Map<String, dynamic>?> _accountCall(
    String method,
    String path,
    Map<String, dynamic> data,
  ) async {
    if (_isPreviewMode) return null;
    try {
      final response = await _request(
        method,
        Uri.parse('${ApiConfig.baseUrl}/auth/$path'),
        body: jsonEncode(data),
      );
      if (response.statusCode != 200) {
        _accountError(response);
        return null;
      }
      final result = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
      if (result['user'] is Map) {
        _currentUser = User.fromJson(Map<String, dynamic>.from(result['user']));
        await _persistSession();
        notifyListeners();
      }
      return result;
    } catch (_) {
      lastError ??= 'Connection interrupted. Your information is kept.';
      return null;
    }
  }

  Future<Map<String, dynamic>?> recoverAccount(
    Map<String, dynamic> data,
  ) async {
    final server = ApiConfig.baseUrl;
    final version = _sessionVersion;
    lastError = null;
    try {
      final response = await http
          .post(
            Uri.parse('$server/auth/recovery/'),
            headers: _headers(requiresAuth: false),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 12));
      if (server != ApiConfig.baseUrl || version != _sessionVersion) {
        return null;
      }
      _accountError(response);
      if (response.statusCode != 200) return null;
      return Map<String, dynamic>.from(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    } catch (_) {
      lastError = 'Connection interrupted. Your information is kept.';
      return null;
    }
  }

  // --- TREES ---

  Future<List<FamilyTree>> getTrees() async {
    if (_isPreviewMode) {
      return [
        FamilyTree(
          id: -1,
          name: 'Example Family',
          description: 'A fictional tree to explore family connections.',
        ),
      ];
    }
    for (final base in ApiConfig.candidateUrls) {
      final url = Uri.parse('$base${ApiConfig.treesEndpoint}');
      try {
        final list = await _getList(url);
        return list.map((item) => FamilyTree.fromJson(item)).toList();
      } catch (e) {
        debugPrint('Error getting trees from $base: $e');
      }
    }
    throw Exception('Unable to load families. Check your connection.');
  }

  Future<FamilyTree?> createTree(String name, String description) async {
    final openedIdentity = identity;
    if (_isPreviewMode) return null;
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.treesEndpoint}');
    try {
      final body = jsonEncode({'name': name, 'description': description});
      final ticket = MutationTicket(identity, 'create-family');
      final key = await ticket.begin(body);
      if (identity != openedIdentity) return null;
      final res = await _postWithAuth(
        url,
        body: body,
        extraHeaders: {'Idempotency-Key': key},
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        await ticket.finish(key);
        if (identity != openedIdentity) return null;
        return FamilyTree.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      }
    } catch (e) {
      debugPrint('Error creating tree: $e');
    }
    return null;
  }

  // --- PEOPLE ---
  Future<FamilyTree?> updateTree(int id, Map<String, dynamic> data) async {
    if (_isPreviewMode) return null;
    try {
      final res = await _patchWithAuth(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.treesEndpoint}$id/'),
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        return FamilyTree.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      }
    } catch (_) {}
    return null;
  }

  Future<bool> deleteTree(int id) async {
    if (_isPreviewMode) return false;
    try {
      return (await _deleteWithAuth(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.treesEndpoint}$id/'),
          )).statusCode ==
          204;
    } catch (_) {
      return false;
    }
  }

  Future<List<Person>> getPeople({int? treeId}) async {
    if (_isPreviewMode) {
      return [
        Person(
          id: -1,
          familyTreeId: -1,
          firstName: 'Amina',
          lastName: 'Exemple',
          gender: 'F',
          generationTier: 1,
          isLiving: false,
        ),
        Person(
          id: -2,
          familyTreeId: -1,
          firstName: 'Jean',
          lastName: 'Exemple',
          gender: 'M',
          generationTier: 2,
        ),
        Person(
          id: -3,
          familyTreeId: -1,
          firstName: 'Maya',
          lastName: 'Exemple',
          gender: 'F',
          generationTier: 3,
        ),
        Person(
          id: -4,
          familyTreeId: -1,
          firstName: 'Noé',
          lastName: 'Exemple',
          gender: 'M',
          generationTier: 3,
        ),
      ];
    }
    for (final base in ApiConfig.candidateUrls) {
      String uriStr = '$base${ApiConfig.peopleEndpoint}';
      if (treeId != null) {
        uriStr += '?family_tree=$treeId';
      }
      final uri = Uri.parse(uriStr);
      final url = uri.replace(
        queryParameters: {...uri.queryParameters, 'compact': '1'},
      );
      try {
        final list = await _getList(url);
        return list.map((item) => Person.fromJson(item)).toList();
      } catch (e) {
        debugPrint('Error getting people from $base: $e');
      }
    }
    throw Exception('Unable to load people. Check your connection.');
  }

  Future<Person?> getPerson(int id) async {
    if (_isPreviewMode) return null;
    try {
      final response = await _getWithAuth(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.peopleEndpoint}$id/'),
      );
      if (response.statusCode == 200) {
        return Person.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (_) {
      /* Keep initials while unavailable. */
    }
    return null;
  }

  Future<Relationship?> getRelationship(int id) async {
    if (_isPreviewMode) return null;
    try {
      final response = await _getWithAuth(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.relationshipsEndpoint}$id/'),
      );
      if (response.statusCode == 200) {
        return Relationship.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
      }
    } catch (_) {
      /* Keep the current editor available on network failure. */
    }
    return null;
  }

  Future<Person?> createPerson(Map<String, dynamic> data) async {
    final openedIdentity = identity;
    if (_isPreviewMode) return null;
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.peopleEndpoint}');
    try {
      final body = jsonEncode(data);
      final ticket = MutationTicket(
        identity,
        'create-person:${data['family_tree']}',
      );
      final key = await ticket.begin(body);
      if (identity != openedIdentity) return null;
      final res = await _postWithAuth(
        url,
        body: body,
        extraHeaders: {'Idempotency-Key': key},
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        await ticket.finish(key);
        if (identity != openedIdentity) return null;
        return Person.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      }
    } catch (e) {
      debugPrint('Error creating person: $e');
    }
    return null;
  }

  Future<Person?> updatePerson(int id, Map<String, dynamic> data) async {
    if (_isPreviewMode) return null;
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.peopleEndpoint}$id/',
    );
    try {
      final res = await _patchWithAuth(url, body: jsonEncode(data));
      if (res.statusCode == 200) {
        return Person.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      }
    } catch (e) {
      debugPrint('Error updating person: $e');
    }
    return null;
  }

  Future<bool> deletePerson(int id) async {
    if (_isPreviewMode) return false;
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.peopleEndpoint}$id/',
    );
    try {
      final res = await _deleteWithAuth(url);
      return res.statusCode == 204 || res.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting person: $e');
      return false;
    }
  }

  Future<Person?> uploadPersonPhoto(
    int personId,
    List<int> bytes,
    String filename,
  ) async {
    if (_isPreviewMode || bytes.length > 10 * 1024 * 1024) return null;
    final version = _sessionVersion;
    final server = ApiConfig.baseUrl;
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.peopleEndpoint}$personId/',
    );
    Future<http.Response> send() async {
      final request = http.MultipartRequest('PATCH', url);
      request.headers.addAll(_headers()..remove('Content-Type'));
      request.files.add(
        http.MultipartFile.fromBytes(
          'profile_picture',
          bytes,
          filename: filename,
        ),
      );
      final stream = await request.send().timeout(const Duration(seconds: 20));
      return http.Response.fromStream(
        stream,
      ).timeout(const Duration(seconds: 20));
    }

    try {
      var response = await send();
      if (version != _sessionVersion || server != ApiConfig.baseUrl) {
        return null;
      }
      if (response.statusCode == 401 && await _tryRefreshToken(url.origin)) {
        response = await send();
      }
      if (version != _sessionVersion || server != ApiConfig.baseUrl) {
        return null;
      }
      _recordError(response);
      if (response.statusCode == 200) {
        return Person.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) {
      lastError = 'Unable to upload photo. Check the connection.';
    }
    return null;
  }

  // --- RELATIONSHIPS ---

  Future<List<Relationship>> getRelationships({int? treeId}) async {
    if (_isPreviewMode) {
      return [
        Relationship(
          id: -1,
          person1Id: -1,
          person2Id: -2,
          relationshipType: 'PARENT',
        ),
        Relationship(
          id: -2,
          person1Id: -2,
          person2Id: -3,
          relationshipType: 'PARENT',
        ),
        Relationship(
          id: -3,
          person1Id: -2,
          person2Id: -4,
          relationshipType: 'PARENT',
        ),
      ];
    }
    for (final base in ApiConfig.candidateUrls) {
      String uriStr = '$base${ApiConfig.relationshipsEndpoint}';
      if (treeId != null) {
        uriStr += '?family_tree=$treeId';
      }
      final url = Uri.parse(uriStr);
      try {
        final list = await _getList(url);
        return list.map((item) => Relationship.fromJson(item)).toList();
      } catch (e) {
        debugPrint('Error getting relationships from $base: $e');
      }
    }
    throw Exception(
      'Unable to load family connections. Check your connection.',
    );
  }

  Future<Relationship?> createRelationship(
    int person1Id,
    int person2Id,
    String type, {
    String? notes,
    Map<String, dynamic>? details,
  }) async {
    if (_isPreviewMode) return null;
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.relationshipsEndpoint}',
    );
    try {
      final res = await _postWithAuth(
        url,
        body: jsonEncode({
          ...?details,
          'person1': person1Id,
          'person2': person2Id,
          'relationship_type': type.toUpperCase(),
          if (notes != null) 'notes': notes,
        }),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return Relationship.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      }
    } catch (e) {
      debugPrint('Error creating relationship: $e');
    }
    return null;
  }

  Future<bool> deleteRelationship(int id) async {
    if (_isPreviewMode) return false;
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.relationshipsEndpoint}$id/',
    );
    try {
      final res = await _deleteWithAuth(url);
      return res.statusCode == 204 || res.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting relationship: $e');
      return false;
    }
  }

  Future<Relationship?> updateRelationship(
    int id,
    Map<String, dynamic> data,
  ) async {
    if (_isPreviewMode) return null;
    try {
      final res = await _patchWithAuth(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.relationshipsEndpoint}$id/'),
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        return Relationship.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      }
    } catch (_) {}
    return null;
  }

  // --- DATA MANAGEMENT (IMPORT / EXPORT) ---

  Future<Map<String, dynamic>?> exportTreeData({int? treeId}) async {
    if (_isPreviewMode) return null;
    final q = treeId != null ? '?tree_id=$treeId' : '';
    final url = Uri.parse('${ApiConfig.baseUrl}/data/export/$q');
    try {
      final res = await _getWithAuth(url);
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error exporting tree data: $e');
    }
    return null;
  }

  Future<bool> importTreeData(
    Map<String, dynamic> data, {
    required int treeId,
    String? requestKey,
  }) async {
    if (_isPreviewMode) return false;
    final openedIdentity = identity;
    final version = _sessionVersion;
    final ticket = MutationTicket(openedIdentity, 'import:$treeId');
    String? key;
    final server = ApiConfig.baseUrl;
    final url = Uri.parse('${ApiConfig.baseUrl}/data/import/');
    Future<http.Response> send() async {
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(_headers()..remove('Content-Type'));
      request.headers['Idempotency-Key'] = key!;
      request.fields['tree_id'] = '$treeId';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          utf8.encode(jsonEncode(data)),
          filename: 'family-tree.json',
        ),
      );
      return await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 30)),
      ).timeout(const Duration(seconds: 30));
    }

    try {
      key = requestKey ?? await ticket.begin(jsonEncode(data));
      if (identity != openedIdentity) return false;
      var res = await send();
      if (version != _sessionVersion || server != ApiConfig.baseUrl) {
        return false;
      }
      if (res.statusCode == 401 && await _tryRefreshToken(url.origin)) {
        res = await send();
      }
      if (version != _sessionVersion || server != ApiConfig.baseUrl) {
        return false;
      }
      _recordError(res);
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (requestKey == null) await ticket.finish(key);
        return identity == openedIdentity;
      }
      return false;
    } catch (e) {
      lastError = 'Unable to import. Check the connection before retrying.';
      debugPrint('Error importing tree data: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getFamilyAccess({int? treeId}) async {
    final openedIdentity = identity;
    try {
      final res = await _getWithAuth(
        Uri.parse(
          '${ApiConfig.baseUrl}/family-access/${treeId == null ? '' : '?tree_id=$treeId'}',
        ),
      );
      if (res.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        if (treeId == null && identity == openedIdentity) {
          pendingFamilyRequests = data['pending_requests'] as int? ?? 0;
          pendingFamilyReviews = data['pending_reviews'] as int? ?? 0;
          notifyListeners();
        }
        return data;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> familyBranches(
    int treeId, {
    Map<String, dynamic>? payload,
  }) async {
    if (_isPreviewMode) return null;
    final openedIdentity = identity;
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/family-branches/${payload == null ? '?tree_id=$treeId' : ''}',
      );
      final response = payload == null
          ? await _getWithAuth(url)
          : await _postWithAuth(url, body: jsonEncode(payload));
      if (identity != openedIdentity) return null;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>?> getContentReports() async {
    try {
      final res = await _getWithAuth(
        Uri.parse('${ApiConfig.baseUrl}/content-reports/'),
      );
      if (res.statusCode == 200) {
        return (jsonDecode(utf8.decode(res.bodyBytes)) as Map)['reports']
            as List;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> reportContent(
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await _postWithAuth(
        Uri.parse('${ApiConfig.baseUrl}/content-reports/'),
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> familyAccess(
    Map<String, dynamic> payload,
  ) async {
    if (_isPreviewMode) return null;
    try {
      final res = await _postWithAuth(
        Uri.parse('${ApiConfig.baseUrl}/family-access/'),
        body: jsonEncode(payload),
      );
      if (res.statusCode < 300) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> createRelative(
    int sourcePersonId,
    String role,
    Map<String, dynamic> person, {
    int? existingPersonId,
    int? coParentId,
    String? relationshipNotes,
    String? relationshipType,
  }) async {
    if (_isPreviewMode) return null;
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/people/$sourcePersonId/create_relative/',
    );
    final body = jsonEncode({
      'role': role,
      'person': person,
      if (existingPersonId != null) 'existing_person_id': existingPersonId,
      if (coParentId != null) 'co_parent_id': coParentId,
      if (relationshipNotes != null) 'relationship_notes': relationshipNotes,
      if (relationshipType != null) 'relationship_type': relationshipType,
    });
    final openedIdentity = identity;
    final ticket = MutationTicket(identity, 'relative:$sourcePersonId:$role');
    final key = await ticket.begin(body);
    if (identity != openedIdentity) return null;
    final response = await _postWithAuth(
      url,
      body: body,
      extraHeaders: {'Idempotency-Key': key},
    );
    if (response.statusCode != 201) {
      return null;
    }
    await ticket.finish(key);
    if (identity != openedIdentity) return null;
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}
