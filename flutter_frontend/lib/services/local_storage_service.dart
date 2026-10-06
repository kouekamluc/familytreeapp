import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/family_tree.dart';
import '../config/api_config.dart';
import 'credential_storage.dart';
import '../models/person.dart';
import '../models/relationship.dart';

class SavedAccount {
  final int userId;
  final String serverUrl;
  final String username;
  final String displayName;
  final String? token;
  final String? refreshToken;
  final String? heritageKey;
  final String? role;
  final DateTime lastUsed;

  SavedAccount({
    required this.userId,
    String? serverUrl,
    required this.username,
    required this.displayName,
    this.token,
    this.refreshToken,
    this.heritageKey,
    this.role,
    DateTime? lastUsed,
  }) : serverUrl = serverUrl ?? ApiConfig.baseUrl,
       lastUsed = lastUsed ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'server_url': serverUrl,
    'username': username,
    'display_name': displayName,
    'token': token,
    'refresh_token': refreshToken,
    'role': role,
    'last_used': lastUsed.toIso8601String(),
  };

  factory SavedAccount.fromJson(Map<String, dynamic> json) => SavedAccount(
    userId: json['user_id'] is int
        ? json['user_id']
        : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
    serverUrl: json['server_url'] ?? '',
    username: json['username'] ?? '',
    displayName: json['display_name'] ?? json['username'] ?? 'Membre',
    token: json['token'],
    refreshToken: json['refresh_token'],
    heritageKey: null,
    role: json['role'] ?? 'FAMILY_MEMBER',
    lastUsed: json['last_used'] != null
        ? DateTime.tryParse(json['last_used'])
        : null,
  );
}

class LocalStorageService {
  static const String _keyServerUrl = 'custom_server_host_url';
  String get _serverScope => base64Url.encode(
    utf8.encode(ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '')),
  );
  String get _keySavedAccounts => 'saved_accounts_v2_$_serverScope';
  String get _keyActiveAccount => 'active_account_v2_$_serverScope';

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

  Future<String> _getAccountScope([String? explicitScope]) async {
    if (explicitScope != null) return explicitScope;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cache_identity_$_serverScope') ??
        'v2_${_serverScope}_guest';
  }

  Future<String> get cacheScope => _getAccountScope();

  Future<void> setActiveAccount(String? username) async {
    final prefs = await SharedPreferences.getInstance();
    if (username == null) {
      await prefs.remove(_keyActiveAccount);
      await prefs.remove('cache_identity_$_serverScope');
      return;
    }
    final accounts = await getSavedAccounts();
    final matches = accounts.where(
      (a) => a.username == username && a.serverUrl == ApiConfig.baseUrl,
    );
    if (matches.isEmpty) return;
    await prefs.setString(_keyActiveAccount, username);
    await prefs.setString(
      'cache_identity_$_serverScope',
      'v2_${_serverScope}_${matches.first.userId}',
    );
  }

  Future<String?> getActiveAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveAccount);
  }

  // --- MULTI-ACCOUNT MANAGEMENT ---

  Future<List<SavedAccount>> getSavedAccounts() async {
    try {
      final server = ApiConfig.baseUrl;
      final str = await CredentialStorage().read(_keySavedAccounts);
      if (server != ApiConfig.baseUrl) return [];
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
      if (account.serverUrl != ApiConfig.baseUrl) return;
      final key = _keySavedAccounts;
      final accounts = await getSavedAccounts();
      // Remove existing entry for same username or key
      accounts.removeWhere(
        (a) =>
            a.userId == account.userId ||
            (account.heritageKey != null &&
                a.heritageKey == account.heritageKey),
      );
      accounts.insert(0, account);
      // Keep up to 6 saved accounts
      if (accounts.length > 6) {
        accounts.removeRange(6, accounts.length);
      }
      final encoded = jsonEncode(accounts.map((a) => a.toJson()).toList());
      await CredentialStorage().write(key, encoded);
      await setActiveAccount(account.username);
    } catch (e) {
      debugPrint('Error saving account: $e');
    }
  }

  Future<void> removeAccount(String username) async {
    try {
      final clean = username.trim().toLowerCase();
      final key = _keySavedAccounts;
      final accounts = await getSavedAccounts();
      final accountsBefore = List<SavedAccount>.from(accounts);
      accounts.removeWhere((a) => a.username.toLowerCase() == clean);
      final encoded = jsonEncode(accounts.map((a) => a.toJson()).toList());
      await CredentialStorage().write(key, encoded);

      // Clean privacy-sensitive cache partition for this account
      for (final account in accountsBefore.where(
        (a) => a.username.toLowerCase() == clean,
      )) {
        await clearAccountCache('v2_${_serverScope}_${account.userId}');
      }

      // If removed account was active, clear active pointer
      final currentActive = await getActiveAccount();
      if (currentActive?.toLowerCase() == clean) {
        await setActiveAccount(null);
      }
    } catch (e) {
      debugPrint('Error removing account: $e');
    }
  }

  Future<void> clearAccountCache(String username) async {
    try {
      final clean = username;
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((k) => k.startsWith('acc_${clean}_'))
          .toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (e) {
      debugPrint('Error clearing account cache: $e');
    }
  }

  Future<void> cacheSnapshot(
    List<FamilyTree> trees,
    int treeId,
    List<Person> people,
    List<Relationship> relationships, {
    required String accountScope,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'acc_${accountScope}_graphs';
    final previous = prefs.getString(key);
    final snapshot = previous == null
        ? <String, dynamic>{}
        : jsonDecode(previous) as Map<String, dynamic>;
    final graphs = Map<String, dynamic>.from(snapshot['graphs'] ?? {});
    graphs['$treeId'] = {
      'people': people.map((p) => p.toJson()).toList(),
      'relationships': relationships.map((r) => r.toJson()).toList(),
    };
    final validIds = trees.map((t) => '${t.id}').toSet();
    graphs.removeWhere((id, _) => !validIds.contains(id));
    await prefs.setString(
      key,
      jsonEncode({
        'trees': trees.map((t) => t.toJson()).toList(),
        'graphs': graphs,
        'selected': treeId,
      }),
    );
  }

  Future<Map<String, dynamic>?> _snapshot(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('acc_${scope}_graphs');
    return encoded == null ? null : jsonDecode(encoded) as Map<String, dynamic>;
  }

  // --- OFFLINE FAMILY TREE DATA STORAGE (PARTITIONED PER ACCOUNT) ---

  Future<void> cacheTrees(
    List<FamilyTree> trees, {
    String? accountScope,
  }) async {
    try {
      final scope = await _getAccountScope(accountScope);
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(trees.map((t) => t.toJson()).toList());
      final previous = await _snapshot(scope);
      if (previous != null && trees.isNotEmpty) {
        final ids = trees.map((t) => '${t.id}').toSet();
        final graphs = Map<String, dynamic>.from(previous['graphs'] ?? {});
        graphs.removeWhere((id, _) => !ids.contains(id));
        final selected = ids.contains('${previous['selected']}')
            ? previous['selected']
            : null;
        await prefs.setString(
          'acc_${scope}_graphs',
          jsonEncode({
            'trees': trees.map((t) => t.toJson()).toList(),
            'graphs': graphs,
            'selected': selected,
          }),
        );
        if (selected == null) await prefs.remove('acc_${scope}_last_tree_id');
      }
      if (trees.isEmpty) {
        await prefs.setString(
          'acc_${scope}_graphs',
          jsonEncode({'trees': [], 'graphs': {}, 'selected': null}),
        );
        await prefs.remove('acc_${scope}_last_tree_id');
        await prefs.remove('acc_${scope}_last_person_id');
      }
      await prefs.setString('acc_${scope}_trees', data);
    } catch (e) {
      debugPrint('Error caching trees locally: $e');
    }
  }

  Future<List<FamilyTree>> getCachedTrees({String? accountScope}) async {
    try {
      final scope = await _getAccountScope(accountScope);
      final prefs = await SharedPreferences.getInstance();
      final snapshot = await _snapshot(scope);
      if (snapshot != null) {
        return (snapshot['trees'] as List)
            .map((item) => FamilyTree.fromJson(item))
            .toList();
      }
      final str = prefs.getString('acc_${scope}_trees');
      if (str == null || str.isEmpty) return [];
      final List decoded = jsonDecode(str);
      return decoded.map((e) => FamilyTree.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error reading cached trees: $e');
      return [];
    }
  }

  Future<void> cachePeople(
    int treeId,
    List<Person> people, {
    String? accountScope,
  }) async {
    try {
      final scope = await _getAccountScope(accountScope);
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(people.map((p) => p.toJson()).toList());
      await prefs.setString('acc_${scope}_people_$treeId', data);
    } catch (e) {
      debugPrint('Error caching people locally: $e');
    }
  }

  Future<List<Person>> getCachedPeople(
    int treeId, {
    String? accountScope,
  }) async {
    try {
      final scope = await _getAccountScope(accountScope);
      final prefs = await SharedPreferences.getInstance();
      final snapshot = await _snapshot(scope);
      if (snapshot != null) {
        return ((snapshot['graphs']['$treeId']?['people'] ?? []) as List)
            .map((item) => Person.fromJson(item))
            .toList();
      }
      final str = prefs.getString('acc_${scope}_people_$treeId');
      if (str == null || str.isEmpty) return [];
      final List decoded = jsonDecode(str);
      return decoded.map((e) => Person.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error reading cached people: $e');
      return [];
    }
  }

  Future<void> cacheRelationships(
    int treeId,
    List<Relationship> rels, {
    String? accountScope,
  }) async {
    try {
      final scope = await _getAccountScope(accountScope);
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(rels.map((r) => r.toJson()).toList());
      await prefs.setString('acc_${scope}_rels_$treeId', data);
    } catch (e) {
      debugPrint('Error caching relationships locally: $e');
    }
  }

  Future<List<Relationship>> getCachedRelationships(
    int treeId, {
    String? accountScope,
  }) async {
    try {
      final scope = await _getAccountScope(accountScope);
      final prefs = await SharedPreferences.getInstance();
      final snapshot = await _snapshot(scope);
      if (snapshot != null) {
        return ((snapshot['graphs']['$treeId']?['relationships'] ?? []) as List)
            .map((item) => Relationship.fromJson(item))
            .toList();
      }
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
