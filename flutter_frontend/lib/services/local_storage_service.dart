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

  // --- ACCOUNT SCOPE ---

  Future<String> _getAccountScope([String? explicitUsername]) async {
    if (explicitUsername != null && explicitUsername.isNotEmpty) {
      return explicitUsername.trim().toLowerCase();
    }
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getString(_keyActiveAccount);
    if (active != null && active.isNotEmpty) {
      return active.trim().toLowerCase();
    }
    return 'guest_preview';
  }

  Future<void> setActiveAccount(String? username) async {
    final prefs = await SharedPreferences.getInstance();
    if (username != null && username.isNotEmpty) {
      await prefs.setString(_keyActiveAccount, username.trim().toLowerCase());
    } else {
      await prefs.remove(_keyActiveAccount);
    }
  }

  Future<String?> getActiveAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveAccount);
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
      await setActiveAccount(account.username);
    } catch (e) {
      debugPrint('Error saving account: $e');
    }
  }

  Future<void> removeAccount(String username) async {
    try {
      final clean = username.trim().toLowerCase();
      final prefs = await SharedPreferences.getInstance();
      final accounts = await getSavedAccounts();
      accounts.removeWhere((a) => a.username.toLowerCase() == clean);
      final encoded = jsonEncode(accounts.map((a) => a.toJson()).toList());
      await prefs.setString(_keySavedAccounts, encoded);

      // Clean privacy-sensitive cache partition for this account
      await clearAccountCache(clean);

      // If removed account was active, clear active pointer
      final currentActive = await getActiveAccount();
      if (currentActive == clean) {
        await setActiveAccount(null);
      }
    } catch (e) {
      debugPrint('Error removing account: $e');
    }
  }

  Future<void> clearAccountCache(String username) async {
    try {
      final clean = username.trim().toLowerCase();
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('acc_${clean}_')).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (e) {
      debugPrint('Error clearing account cache: $e');
    }
  }

  // --- OFFLINE FAMILY TREE DATA STORAGE (PARTITIONED PER ACCOUNT) ---

  Future<void> cacheTrees(List<FamilyTree> trees, {String? accountScope}) async {
    try {
      final scope = await _getAccountScope(accountScope);
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(trees.map((t) => t.toJson()).toList());
      await prefs.setString('acc_${scope}_trees', data);
    } catch (e) {
      debugPrint('Error caching trees locally: $e');
    }
  }

  Future<List<FamilyTree>> getCachedTrees({String? accountScope}) async {
    try {
      final scope = await _getAccountScope(accountScope);
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('acc_${scope}_trees');
      if (str == null || str.isEmpty) return [];
      final List decoded = jsonDecode(str);
      return decoded.map((e) => FamilyTree.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error reading cached trees: $e');
      return [];
    }
  }

  Future<void> cachePeople(int treeId, List<Person> people, {String? accountScope}) async {
    try {
      final scope = await _getAccountScope(accountScope);
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(people.map((p) => p.toJson()).toList());
      await prefs.setString('acc_${scope}_people_$treeId', data);
    } catch (e) {
      debugPrint('Error caching people locally: $e');
    }
  }

  Future<List<Person>> getCachedPeople(int treeId, {String? accountScope}) async {
    try {
      final scope = await _getAccountScope(accountScope);
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('acc_${scope}_people_$treeId');
      if (str == null || str.isEmpty) return [];
      final List decoded = jsonDecode(str);
      return decoded.map((e) => Person.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error reading cached people: $e');
      return [];
    }
  }

  Future<void> cacheRelationships(int treeId, List<Relationship> rels, {String? accountScope}) async {
    try {
      final scope = await _getAccountScope(accountScope);
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(rels.map((r) => r.toJson()).toList());
      await prefs.setString('acc_${scope}_rels_$treeId', data);
    } catch (e) {
      debugPrint('Error caching relationships locally: $e');
    }
  }

  Future<List<Relationship>> getCachedRelationships(int treeId, {String? accountScope}) async {
    try {
      final scope = await _getAccountScope(accountScope);
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('acc_${scope}_rels_$treeId');
      if (str == null || str.isEmpty) return [];
      final List decoded = jsonDecode(str);
      return decoded.map((e) => Relationship.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error reading cached relationships: $e');
      return [];
    }
  }

  Future<void> saveLastActiveTreeId(int id, {String? accountScope}) async {
    final scope = await _getAccountScope(accountScope);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('acc_${scope}_last_tree_id', id);
  }

  Future<int?> getLastActiveTreeId({String? accountScope}) async {
    final scope = await _getAccountScope(accountScope);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('acc_${scope}_last_tree_id');
  }

  Future<void> saveLastActivePersonId(int id, {String? accountScope}) async {
    final scope = await _getAccountScope(accountScope);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('acc_${scope}_last_person_id', id);
  }

  Future<int?> getLastActivePersonId({String? accountScope}) async {
    final scope = await _getAccountScope(accountScope);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('acc_${scope}_last_person_id');
  }
}
