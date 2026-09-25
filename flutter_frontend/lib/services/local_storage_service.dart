import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/family_tree.dart';
import '../models/person.dart';
import '../models/relationship.dart';

class SavedAccount {
  final int userId;
  final String username;
  final String displayName;
  final String? token;
  final String? refreshToken;
  final String? heritageKey;
  final String? role;
  final DateTime lastUsed;

  SavedAccount({
    required this.userId,
    required this.username,
    required this.displayName,
    this.token,
    this.refreshToken,
    this.heritageKey,
    this.role,
    DateTime? lastUsed,
  }) : lastUsed = lastUsed ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'username': username,
        'display_name': displayName,
        'token': token,
        'refresh_token': refreshToken,
        'heritage_key': heritageKey,
        'role': role,
        'last_used': lastUsed.toIso8601String(),
      };

  factory SavedAccount.fromJson(Map<String, dynamic> json) => SavedAccount(
        userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
        username: json['username'] ?? '',
        displayName: json['display_name'] ?? json['username'] ?? 'Membre',
        token: json['token'],
        refreshToken: json['refresh_token'],
        heritageKey: json['heritage_key'],
        role: json['role'] ?? 'FAMILY_MEMBER',
        lastUsed: json['last_used'] != null ? DateTime.tryParse(json['last_used']) : null,
      );
}

class LocalStorageService {
  static const String _keyServerUrl = 'custom_server_host_url';
  static const String _keySavedAccounts = 'saved_accounts_list';
  static const String _keyActiveAccount = 'active_account_username';
  static const String _keyOfflineTrees = 'offline_trees_cache';
  static const String _keyPrefixPeople = 'offline_people_tree_';
  static const String _keyPrefixRels = 'offline_rels_tree_';
  static const String _keyLastTreeId = 'offline_last_tree_id';
  static const String _keyLastPersonId = 'offline_last_person_id';

  // Singleton pattern
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  // --- SERVER HOST IP MANAGEMENT ---

  Future<void> saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    await prefs.setString(_keyServerUrl, clean);
  }

  Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl);
  }

  // --- MULTI-ACCOUNT MANAGEMENT ---

  Future<List<SavedAccount>> getSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keySavedAccounts);
      if (str == null || str.isEmpty) return [];
      final List decoded = jsonDecode(str);
      return decoded.map((e) => SavedAccount.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading saved accounts: $e');
      return [];
    }
  }

  Future<void> saveAccount(SavedAccount account) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accounts = await getSavedAccounts();
      // Remove existing entry for same username or key
      accounts.removeWhere((a) =>
          a.username.toLowerCase() == account.username.toLowerCase() ||
          (account.heritageKey != null && a.heritageKey == account.heritageKey));
      accounts.insert(0, account);
      // Keep up to 6 saved accounts
      if (accounts.length > 6) {
        accounts.removeRange(6, accounts.length);
      }
      final encoded = jsonEncode(accounts.map((a) => a.toJson()).toList());
      await prefs.setString(_keySavedAccounts, encoded);
      await prefs.setString(_keyActiveAccount, account.username);
    } catch (e) {
      debugPrint('Error saving account: $e');
    }
  }

  Future<void> removeAccount(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accounts = await getSavedAccounts();
      accounts.removeWhere((a) => a.username.toLowerCase() == username.toLowerCase());
      final encoded = jsonEncode(accounts.map((a) => a.toJson()).toList());
      await prefs.setString(_keySavedAccounts, encoded);
    } catch (e) {
      debugPrint('Error removing account: $e');
    }
  }

  // --- OFFLINE FAMILY TREE DATA STORAGE ---

  Future<void> cacheTrees(List<FamilyTree> trees) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(trees.map((t) => t.toJson()).toList());
      await prefs.setString(_keyOfflineTrees, data);
    } catch (e) {
      debugPrint('Error caching trees locally: $e');
    }
  }

  Future<List<FamilyTree>> getCachedTrees() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyOfflineTrees);
      if (str == null || str.isEmpty) return [];
      final List decoded = jsonDecode(str);
      return decoded.map((e) => FamilyTree.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error reading cached trees: $e');
      return [];
    }
  }

  Future<void> cachePeople(int treeId, List<Person> people) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(people.map((p) => p.toJson()).toList());
      await prefs.setString('$_keyPrefixPeople$treeId', data);
    } catch (e) {
      debugPrint('Error caching people locally: $e');
    }
  }

  Future<List<Person>> getCachedPeople(int treeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('$_keyPrefixPeople$treeId');
      if (str == null || str.isEmpty) return [];
      final List decoded = jsonDecode(str);
      return decoded.map((e) => Person.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error reading cached people: $e');
      return [];
    }
  }

  Future<void> cacheRelationships(int treeId, List<Relationship> rels) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(rels.map((r) => r.toJson()).toList());
      await prefs.setString('$_keyPrefixRels$treeId', data);
    } catch (e) {
      debugPrint('Error caching relationships locally: $e');
    }
  }

  Future<List<Relationship>> getCachedRelationships(int treeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('$_keyPrefixRels$treeId');
      if (str == null || str.isEmpty) return [];
      final List decoded = jsonDecode(str);
      return decoded.map((e) => Relationship.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error reading cached relationships: $e');
      return [];
    }
  }

  Future<void> saveLastActiveTreeId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastTreeId, id);
  }

  Future<int?> getLastActiveTreeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLastTreeId);
  }

  Future<void> saveLastActivePersonId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastPersonId, id);
  }

  Future<int?> getLastActivePersonId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLastPersonId);
  }
}
