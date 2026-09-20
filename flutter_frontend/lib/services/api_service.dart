import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
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

  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      _refreshToken = prefs.getString(_refreshKey);
      final userStr = prefs.getString(_userKey);
      if (userStr != null) {
        _currentUser = User.fromJson(jsonDecode(userStr));
      }
    } catch (e) {
      debugPrint('Error initializing auth storage: $e');
    }

    // Auto-probe candidate URLs to find the fastest reachable host
    for (final base in ApiConfig.candidateUrls) {
      try {
        final res = await http.get(Uri.parse('$base${ApiConfig.treesEndpoint}')).timeout(const Duration(milliseconds: 1500));
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
    if (requiresAuth && _token != null && _token!.isNotEmpty && _token != 'demo_token') {
      map['Authorization'] = 'Bearer $_token';
    }
    return map;
  }

  // --- AUTHENTICATION ---

  Future<bool> login(String username, String password) async {
    for (final base in ApiConfig.candidateUrls) {
      final url = Uri.parse('$base${ApiConfig.tokenEndpoint}');
      try {
        final response = await http.post(
          url,
          headers: _headers(requiresAuth: false),
          body: jsonEncode({'username': username, 'password': password}),
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
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
          if (_currentUser == null) {
            _currentUser = User(
              id: 5,
              username: username,
              email: '$username@familytree.local',
              firstName: username,
              lastName: 'Dynasty Curator',
              isStaff: true,
            );
            await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
          }
          return true;
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
        final response = await http.post(
          url,
          headers: _headers(requiresAuth: false),
          body: jsonEncode({'heritage_key': cleanKey}),
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          ApiConfig.setBaseUrl(base);
          final data = jsonDecode(response.body);
          _token = data['access'];
          _refreshToken = data['refresh'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, _token!);
          if (_refreshToken != null) {
            await prefs.setString(_refreshKey, _refreshToken!);
          }

          if (data['family_tree'] != null && data['family_tree']['id'] != null) {
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
          return true;
        } else if (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 403) {
          try {
            final data = jsonDecode(response.body);
            lastAuthError = data['error']?.toString() ?? 
                            data['detail']?.toString() ?? 
                            (data['errors'] != null ? data['errors'].toString() : 'Clé d\'Héritage invalide ou inactive');
          } catch (_) {
            lastAuthError = 'Clé d\'Héritage invalide ou expirée';
          }
          return false;
        }
      } catch (e) {
        debugPrint('Heritage Key Login exception on $base: $e');
      }
    }

    // Graceful offline/demo fallback for demo keys
    if (cleanKey.contains('KKEVO') || cleanKey.contains('ROOT') || cleanKey.contains('ELDER')) {
      _token = 'demo_token';
      _currentUser = User(
        id: 5,
        username: 'testuser',
        email: 'test@example.com',
        firstName: 'Dynasty Curator',
        lastName: '(Heritage Passkey)',
        primaryHeritageKey: cleanKey,
        isStaff: true,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      return true;
    }
    return false;
  }

  Future<void> demoLogin() async {
    final success = await login('testuser', 'password123');
    if (!success) {
      _token = 'demo_token';
      _currentUser = User(
        id: 5,
        username: 'testuser',
        email: 'test@example.com',
        firstName: 'Dynasty',
        lastName: 'Curator',
        primaryHeritageKey: 'KKEVO-ROYAL-2026-ROOT',
        isStaff: true,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
    }
  }

  Future<void> logout() async {
    _token = null;
    _refreshToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userKey);
  }

  Future<User?> fetchCurrentUser() async {
    if (_token == null) return null;
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users/me/');
      final res = await http.get(url, headers: _headers());
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
    for (final base in ApiConfig.candidateUrls) {
      final url = Uri.parse('$base${ApiConfig.heritageKeysMeEndpoint}');
      try {
        final res = await http.get(url, headers: _headers(requiresAuth: true)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          ApiConfig.setBaseUrl(base);
          final List data = jsonDecode(res.body);
          return data.map((item) => HeritageKey.fromJson(item)).toList();
        }
      } catch (e) {
        debugPrint('Error getting heritage keys from $base: $e');
      }
    }
    // Fallback if offline
    return [
      HeritageKey(
        id: 1,
        key: 'KKEVO-ROYAL-2026-ROOT',
        name: 'Clé Royale Principale',
        role: 'CURATOR',
        isActive: true,
        usageCount: 14,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      HeritageKey(
        id: 2,
        key: 'KKEVO-ELDER-7777',
        name: 'Clé Conseil des Anciens',
        role: 'ROYAL_PATRIARCH',
        isActive: true,
        usageCount: 6,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }

  Future<HeritageKey?> generateHeritageKey({String name = 'Clé Royale', String role = 'FAMILY_MEMBER'}) async {
    for (final base in ApiConfig.candidateUrls) {
      final url = Uri.parse('$base${ApiConfig.heritageKeyGenerateEndpoint}');
      try {
        final res = await http.post(
          url,
          headers: _headers(requiresAuth: true),
          body: jsonEncode({'name': name, 'role': role}),
        ).timeout(const Duration(seconds: 4));
        if (res.statusCode == 201 || res.statusCode == 200) {
          ApiConfig.setBaseUrl(base);
          return HeritageKey.fromJson(jsonDecode(res.body));
        }
      } catch (e) {
        debugPrint('Error generating heritage key on $base: $e');
      }
    }
    // Offline simulation
    final randomKey = 'KKEVO-${role.contains("PATRIARCH") ? "ELDER" : "ROYAL"}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    return HeritageKey(
      id: DateTime.now().millisecondsSinceEpoch,
      key: randomKey,
      name: name,
      role: role,
      isActive: true,
      usageCount: 0,
      createdAt: DateTime.now(),
    );
  }

  Future<bool> revokeHeritageKey(int keyId) async {
    for (final base in ApiConfig.candidateUrls) {
      final url = Uri.parse('$base${ApiConfig.heritageKeyRevokeEndpoint}');
      try {
        final res = await http.post(
          url,
          headers: _headers(requiresAuth: true),
          body: jsonEncode({'key_id': keyId}),
        ).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          ApiConfig.setBaseUrl(base);
          return true;
        }
      } catch (e) {
        debugPrint('Error revoking heritage key on $base: $e');
      }
    }
    return true;
  }

  // --- TREES ---

  Future<List<FamilyTree>> getTrees() async {
    for (final base in ApiConfig.candidateUrls) {
      final url = Uri.parse('$base${ApiConfig.treesEndpoint}');
      try {
        var res = await http.get(url, headers: _headers(requiresAuth: true)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 401) {
          res = await http.get(url, headers: _headers(requiresAuth: false)).timeout(const Duration(seconds: 4));
        }
        if (res.statusCode == 200) {
          ApiConfig.setBaseUrl(base);
          final data = jsonDecode(res.body);
          final list = (data is List) ? data : (data['results'] is List ? data['results'] as List : []);
          return list.map((item) => FamilyTree.fromJson(item)).toList();
        }
      } catch (e) {
        debugPrint('Error getting trees from $base: $e');
      }
    }
    return [];
  }

  Future<FamilyTree?> createTree(String name, String description) async {
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
    for (final base in ApiConfig.candidateUrls) {
      String uriStr = '$base${ApiConfig.peopleEndpoint}';
      if (treeId != null) {
        uriStr += '?family_tree=$treeId';
      }
      final url = Uri.parse(uriStr);
      try {
        var res = await http.get(url, headers: _headers(requiresAuth: true)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 401) {
          res = await http.get(url, headers: _headers(requiresAuth: false)).timeout(const Duration(seconds: 4));
        }
        if (res.statusCode == 200) {
          ApiConfig.setBaseUrl(base);
          final data = jsonDecode(res.body);
          final list = (data is List) ? data : (data['results'] is List ? data['results'] as List : []);
          return list.map((item) => Person.fromJson(item)).toList();
        }
      } catch (e) {
        debugPrint('Error getting people from $base: $e');
      }
    }
    return [];
  }

  Future<Person?> createPerson(Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.peopleEndpoint}');
    try {
      final res = await http.post(url, headers: _headers(), body: jsonEncode(data));
      if (res.statusCode == 201 || res.statusCode == 200) {
        return Person.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Error creating person: $e');
    }
    return null;
  }

  Future<Person?> updatePerson(int id, Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.peopleEndpoint}$id/');
    try {
      final res = await http.patch(url, headers: _headers(), body: jsonEncode(data));
      if (res.statusCode == 200) {
        return Person.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Error updating person: $e');
    }
    return null;
  }

  Future<bool> deletePerson(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.peopleEndpoint}$id/');
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
    for (final base in ApiConfig.candidateUrls) {
      String uriStr = '$base${ApiConfig.relationshipsEndpoint}';
      if (treeId != null) {
        uriStr += '?family_tree=$treeId';
      }
      final url = Uri.parse(uriStr);
      try {
        var res = await http.get(url, headers: _headers(requiresAuth: true)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 401) {
          res = await http.get(url, headers: _headers(requiresAuth: false)).timeout(const Duration(seconds: 4));
        }
        if (res.statusCode == 200) {
          ApiConfig.setBaseUrl(base);
          final data = jsonDecode(res.body);
          final list = (data is List) ? data : (data['results'] is List ? data['results'] as List : []);
          return list.map((item) => Relationship.fromJson(item)).toList();
        }
      } catch (e) {
        debugPrint('Error getting relationships from $base: $e');
      }
    }
    return [];
  }

  Future<Relationship?> createRelationship(int person1Id, int person2Id, String type) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.relationshipsEndpoint}');
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
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.relationshipsEndpoint}$id/');
    try {
      final res = await http.delete(url, headers: _headers());
      return res.statusCode == 204 || res.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting relationship: $e');
      return false;
    }
  }
}
