import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/family_tree.dart';
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

  // --- AUTHENTICATION ---

  Future<bool> login(String username, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tokenEndpoint}');
    try {
      final response = await http.post(
        url,
        headers: _headers(requiresAuth: false),
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        _refreshToken = data['refresh'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _token!);
        if (_refreshToken != null) {
          await prefs.setString(_refreshKey, _refreshToken!);
        }

        // Fetch user profile or synthesize demo profile
        await fetchCurrentUser();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login exception: $e');
      return false;
    }
  }

  Future<void> demoLogin() async {
    // Attempt standard credentials or fallback to demo session
    final success = await login('admin', 'admin');
    if (!success) {
      // Mock session for quick demo preview if backend is offline or unseeded
      _token = 'demo_token';
      _currentUser = User(
        id: 1,
        username: 'royal_curator',
        email: 'curator@royalancestry.org',
        firstName: 'Royal',
        lastName: 'Curator',
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
    } catch (_) {
      // Fallback if users/me doesn't exist
    }
    return _currentUser;
  }

  // --- TREES ---

  Future<List<FamilyTree>> getTrees() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.treesEndpoint}');
    try {
      final res = await http.get(url, headers: _headers(requiresAuth: false));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data is List) ? data : (data['results'] is List ? data['results'] as List : []);
        return list.map((item) => FamilyTree.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error getting trees: $e');
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
    String uriStr = '${ApiConfig.baseUrl}${ApiConfig.peopleEndpoint}';
    if (treeId != null) {
      uriStr += '?family_tree=$treeId';
    }
    final url = Uri.parse(uriStr);
    try {
      final res = await http.get(url, headers: _headers(requiresAuth: false));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data is List) ? data : (data['results'] is List ? data['results'] as List : []);
        return list.map((item) => Person.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error getting people: $e');
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
    String uriStr = '${ApiConfig.baseUrl}${ApiConfig.relationshipsEndpoint}';
    if (treeId != null) {
      uriStr += '?family_tree=$treeId';
    }
    final url = Uri.parse(uriStr);
    try {
      final res = await http.get(url, headers: _headers(requiresAuth: false));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data is List) ? data : (data['results'] is List ? data['results'] as List : []);
        return list.map((item) => Relationship.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error getting relationships: $e');
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
