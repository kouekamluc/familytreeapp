import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'local_storage_service.dart';
import '../models/family_tree.dart';
import '../models/heritage_key.dart';
import '../models/person.dart';
import '../models/relationship.dart';
import '../models/user.dart';

class ApiService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshKey = 'auth_refresh';
  static const String _userKey = 'auth_user';

  String? _token;
  String? _refreshToken;
  User? _currentUser;
  bool _isPreviewMode = false;

  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isAuthenticated =>
      _isPreviewMode || (_token != null && _token!.isNotEmpty);
  bool get isPreviewMode => _isPreviewMode;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      _refreshToken = prefs.getString(_refreshKey);
      if (_token == 'demo_token') {
        _token = null;
        _refreshToken = null;
        await prefs.remove(_tokenKey);
        await prefs.remove(_refreshKey);
        await prefs.remove(_userKey);
      }
      final userStr = prefs.getString(_userKey);
      if (_token != null && userStr != null) {
        _currentUser = User.fromJson(jsonDecode(userStr));
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
            .get(Uri.parse('$base${ApiConfig.treesEndpoint}'))
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode < 500) {
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
    if (requiresAuth && _token != null && _token!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_token';
    }
    return map;
  }

  Future<bool> _tryRefreshToken(String origin) async {
    if (_refreshToken == null) return false;
    try {
      final refresh = await http
          .post(
            Uri.parse('$origin/api/auth/token/refresh/'),
            headers: _headers(requiresAuth: false),
            body: jsonEncode({'refresh': _refreshToken}),
          )
          .timeout(const Duration(seconds: 4));
      if (refresh.statusCode == 200) {
        _token = jsonDecode(refresh.body)['access'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _token!);
        return true;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }
    return false;
  }

  Future<http.Response> _getWithAuth(Uri url) async {
    var response = await http
        .get(url, headers: _headers())
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _tryRefreshToken(url.origin);
      if (refreshed) {
        response = await http
            .get(url, headers: _headers())
            .timeout(const Duration(seconds: 5));
      }
    }
    return response;
  }

  Future<http.Response> _postWithAuth(Uri url, {Object? body}) async {
    var response = await http
        .post(url, headers: _headers(), body: body)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _tryRefreshToken(url.origin);
      if (refreshed) {
        response = await http
            .post(url, headers: _headers(), body: body)
            .timeout(const Duration(seconds: 5));
      }
    }
    return response;
  }

  Future<http.Response> _patchWithAuth(Uri url, {Object? body}) async {
    var response = await http
        .patch(url, headers: _headers(), body: body)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _tryRefreshToken(url.origin);
      if (refreshed) {
        response = await http
            .patch(url, headers: _headers(), body: body)
            .timeout(const Duration(seconds: 5));
      }
    }
    return response;
  }

  // ignore: unused_element
  Future<http.Response> _putWithAuth(Uri url, {Object? body}) async {
    var response = await http
        .put(url, headers: _headers(), body: body)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _tryRefreshToken(url.origin);
      if (refreshed) {
        response = await http
            .put(url, headers: _headers(), body: body)
            .timeout(const Duration(seconds: 5));
      }
    }
    return response;
  }

  Future<http.Response> _deleteWithAuth(Uri url) async {
    var response = await http
        .delete(url, headers: _headers())
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _tryRefreshToken(url.origin);
      if (refreshed) {
        response = await http
            .delete(url, headers: _headers())
            .timeout(const Duration(seconds: 5));
      }
    }
    return response;
  }

  // --- AUTHENTICATION ---

  Future<bool> login(String username, String password) async {
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
          _isPreviewMode = false;
          _currentUser = null;
          ApiConfig.setBaseUrl(base);
          final data = jsonDecode(response.body);
          _token = data['access'];
          _refreshToken = data['refresh'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, _token!);
          if (_refreshToken != null) {
            await prefs.setString(_refreshKey, _refreshToken!);
          }

          await fetchCurrentUser();
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
          return _currentUser != null;
        }
      } catch (e) {
        debugPrint('Login exception on $base: $e');
      }
    }
    return false;
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    lastAuthError = null;
    for (final base in ApiConfig.candidateUrls) {
      final url = Uri.parse('$base/api/register/');
      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'username': username,
                'email': email,
                'password': password,
                if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
                if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
              }),
            )
            .timeout(const Duration(seconds: 5));

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
            lastAuthError = 'Erreur d\'inscription (${response.statusCode})';
          }
        }
      } catch (e) {
        debugPrint('Registration exception on $base: $e');
      }
    }
    lastAuthError ??= 'Impossible de contacter le serveur d\'inscription.';
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
          _isPreviewMode = false;
          ApiConfig.setBaseUrl(base);
          final data = jsonDecode(response.body);
          _token = data['access'];
          _refreshToken = data['refresh'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, _token!);
          if (_refreshToken != null) {
            await prefs.setString(_refreshKey, _refreshToken!);
          }

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
            await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
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
                heritageKey: cleanKey,
                role: 'FAMILY_MEMBER',
              ),
            );
          }
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
                    : 'Clé d\'Héritage invalide ou inactive');
          } catch (_) {
            lastAuthError = 'Clé d\'Héritage invalide ou expirée';
          }
          return false;
        }
      } catch (e) {
        debugPrint('Heritage Key Login exception on $base: $e');
      }
    }

    lastAuthError ??=
        'Connexion indisponible. Réessayez lorsque le réseau est disponible.';
    return false;
  }

  Future<void> demoLogin() async {
    _isPreviewMode = true;
    _token = null;
    _refreshToken = null;
    _currentUser = User(
      id: 0,
      username: 'preview',
      email: '',
      firstName: 'Découverte',
      lastName: '',
      isStaff: false,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userKey);
    lastInvitedTreeId = null;
    lastInvitedPersonId = null;
  }

  Future<void> logout() async {
    _isPreviewMode = false;
    _token = null;
    _refreshToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userKey);
  }

  Future<bool> switchToAccount(SavedAccount account) async {
    _isPreviewMode = false;
    final previousToken = _token;
    final previousRefreshToken = _refreshToken;
    final previousUser = _currentUser;

    // Reset current user so previous identity is NEVER retained on failure
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    if (account.token != null) {
      _token = account.token;
      _refreshToken = account.refreshToken;
      await prefs.setString(_tokenKey, _token!);
      if (_refreshToken != null) {
        await prefs.setString(_refreshKey, _refreshToken!);
      }
      final user = await fetchCurrentUser();
      if (user != null) {
        await LocalStorageService().setActiveAccount(user.username);
        return true;
      }
    } else if (account.heritageKey != null) {
      final success = await loginWithHeritageKey(account.heritageKey!);
      if (success && _currentUser != null) {
        await LocalStorageService().setActiveAccount(_currentUser!.username);
        return true;
      }
    }

    // Switch failed: revert safely or clear
    if (previousToken != null) {
      _token = previousToken;
      _refreshToken = previousRefreshToken;
      _currentUser = previousUser;
      await prefs.setString(_tokenKey, _token!);
      if (_refreshToken != null) {
        await prefs.setString(_refreshKey, _refreshToken!);
      }
      if (previousUser != null) {
        await LocalStorageService().setActiveAccount(previousUser.username);
      }
    } else {
      _token = null;
      _refreshToken = null;
      _currentUser = null;
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshKey);
      await prefs.remove(_userKey);
      await LocalStorageService().setActiveAccount(null);
    }
    return false;
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        return _currentUser;
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        _currentUser = null;
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
    throw Exception('Impossible de charger vos clés. Vérifiez la connexion.');
  }

  Future<HeritageKey?> generateHeritageKey({
    String name = 'Clé Royale',
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

  // --- TREES ---

  Future<List<FamilyTree>> getTrees() async {
    if (_isPreviewMode) {
      return [
        FamilyTree(
          id: -1,
          name: 'Famille Exemple',
          description: 'Un arbre fictif pour découvrir les liens familiaux.',
        ),
      ];
    }
    for (final base in ApiConfig.candidateUrls) {
      final url = Uri.parse('$base${ApiConfig.treesEndpoint}');
      try {
        final res = await _getWithAuth(url);
        if (res.statusCode == 200) {
          ApiConfig.setBaseUrl(base);
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          final list = (data is List)
              ? data
              : (data['results'] is List ? data['results'] as List : []);
          final trees = list.map((item) => FamilyTree.fromJson(item)).toList();
          await LocalStorageService().cacheTrees(trees);
          return trees;
        }
      } catch (e) {
        debugPrint('Error getting trees from $base: $e');
      }
    }
    throw Exception('Impossible de charger les arbres. Vérifiez la connexion.');
  }

  Future<FamilyTree?> createTree(String name, String description) async {
    if (_isPreviewMode) return null;
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.treesEndpoint}');
    try {
      final res = await _postWithAuth(
        url,
        body: jsonEncode({'name': name, 'description': description}),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return FamilyTree.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      }
    } catch (e) {
      debugPrint('Error creating tree: $e');
    }
    return null;
  }

  // --- PEOPLE ---

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
      final url = Uri.parse(uriStr);
      try {
        final res = await _getWithAuth(url);
        if (res.statusCode == 200) {
          ApiConfig.setBaseUrl(base);
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          final list = (data is List)
              ? data
              : (data['results'] is List ? data['results'] as List : []);
          final people = list.map((item) => Person.fromJson(item)).toList();
          if (treeId != null) {
            await LocalStorageService().cachePeople(treeId, people);
          }
          return people;
        }
      } catch (e) {
        debugPrint('Error getting people from $base: $e');
      }
    }
    throw Exception(
      'Impossible de charger les membres. Vérifiez la connexion.',
    );
  }

  Future<Person?> createPerson(Map<String, dynamic> data) async {
    if (_isPreviewMode) return null;
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.peopleEndpoint}');
    try {
      final res = await _postWithAuth(
        url,
        body: jsonEncode(data),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
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
      final res = await _patchWithAuth(
        url,
        body: jsonEncode(data),
      );
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

  Future<String?> uploadPersonPhoto(int personId, List<int> bytes, String filename) async {
    if (_isPreviewMode) return null;
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.peopleEndpoint}$personId/');
    try {
      final req = http.MultipartRequest('PATCH', url);
      req.headers.addAll(_headers());
      req.files.add(http.MultipartFile.fromBytes(
        'profile_picture',
        bytes,
        filename: filename,
      ));
      final streamed = await req.send().timeout(const Duration(seconds: 15));
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return data['profile_picture'] ?? data['avatar'];
      }
    } catch (e) {
      debugPrint('Error uploading photo: $e');
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
        final res = await _getWithAuth(url);
        if (res.statusCode == 200) {
          ApiConfig.setBaseUrl(base);
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          final list = (data is List)
              ? data
              : (data['results'] is List ? data['results'] as List : []);
          final rels = list.map((item) => Relationship.fromJson(item)).toList();
          if (treeId != null) {
            await LocalStorageService().cacheRelationships(treeId, rels);
          }
          return rels;
        }
      } catch (e) {
        debugPrint('Error getting relationships from $base: $e');
      }
    }
    throw Exception(
      'Impossible de charger les liens familiaux. Vérifiez la connexion.',
    );
  }

  Future<Relationship?> createRelationship(
    int person1Id,
    int person2Id,
    String type, {
    String? notes,
  }) async {
    if (_isPreviewMode) return null;
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.relationshipsEndpoint}',
    );
    try {
      final res = await _postWithAuth(
        url,
        body: jsonEncode({
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

  Future<bool> importTreeData(Map<String, dynamic> data) async {
    if (_isPreviewMode) return false;
    final url = Uri.parse('${ApiConfig.baseUrl}/data/import/');
    try {
      final res = await _postWithAuth(url, body: jsonEncode(data));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error importing tree data: $e');
      return false;
    }
  }
}
