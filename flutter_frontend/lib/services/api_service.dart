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

  Future<http.Response> _getWithAuth(Uri url) async {
    var response = await http
        .get(url, headers: _headers())
        .timeout(const Duration(seconds: 4));
    if (response.statusCode == 401 && _refreshToken != null) {
      try {
        final refresh = await http
            .post(
              Uri.parse('${url.origin}/api/auth/token/refresh/'),
              headers: _headers(requiresAuth: false),
              body: jsonEncode({'refresh': _refreshToken}),
            )
            .timeout(const Duration(seconds: 4));
        if (refresh.statusCode == 200) {
          _token = jsonDecode(refresh.body)['access'] as String;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, _token!);
          response = await http
              .get(url, headers: _headers())
              .timeout(const Duration(seconds: 4));
        }
      } catch (e) {
        debugPrint('Token refresh failed: $e');
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
    _token = account.token;
    _refreshToken = account.refreshToken;
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString(_tokenKey, _token!);
    } else {
      await prefs.remove(_tokenKey);
    }
    if (_refreshToken != null) {
      await prefs.setString(_refreshKey, _refreshToken!);
    } else {
      await prefs.remove(_refreshKey);
    }

    if (account.token != null) {
      await fetchCurrentUser();
    } else if (account.heritageKey != null) {
      return await loginWithHeritageKey(account.heritageKey!);
    }
    return _currentUser != null;
  }

  Future<User?> fetchCurrentUser() async {
    if (_isPreviewMode) return _currentUser;
    if (_token == null) return null;
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users/me/');
      final res = await _getWithAuth(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _currentUser = User.fromJson(data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        return _currentUser;
      }
    } catch (_) {}
    return _currentUser;
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
          final List data = jsonDecode(res.body);
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
        final res = await http
            .post(
              url,
              headers: _headers(requiresAuth: true),
              body: jsonEncode({'name': name, 'role': role}),
            )
            .timeout(const Duration(seconds: 4));
        if (res.statusCode == 201 || res.statusCode == 200) {
          ApiConfig.setBaseUrl(base);
          return HeritageKey.fromJson(jsonDecode(res.body));
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
        final res = await http
            .post(
              url,
              headers: _headers(requiresAuth: true),
              body: jsonEncode({'key_id': keyId}),
            )
            .timeout(const Duration(seconds: 4));
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
      final res = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({'name': name, 'description': description}),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return FamilyTree.fromJson(jsonDecode(res.body));
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
      final res = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode(data),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return Person.fromJson(jsonDecode(res.body));
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
      final res = await http.patch(
        url,
        headers: _headers(),
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        return Person.fromJson(jsonDecode(res.body));
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
      final res = await http.delete(url, headers: _headers());
      return res.statusCode == 204 || res.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting person: $e');
      return false;
    }
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
          final data = jsonDecode(res.body);
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
    String type,
  ) async {
    if (_isPreviewMode) return null;
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.relationshipsEndpoint}',
    );
    try {
      final res = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({
          'person1': person1Id,
          'person2': person2Id,
          'relationship_type': type,
        }),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return Relationship.fromJson(jsonDecode(res.body));
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
      final res = await http.delete(url, headers: _headers());
      return res.statusCode == 204 || res.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting relationship: $e');
      return false;
    }
  }
}
