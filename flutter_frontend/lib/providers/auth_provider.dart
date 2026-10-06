import 'package:flutter/material.dart';
import '../models/heritage_key.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  bool _isLoading = false;
  String? _errorMessage;
  List<HeritageKey> _heritageKeys = [];
  bool _isLoadingKeys = false;
  List<SavedAccount> _savedAccounts = [];
  late String _identity;
  int _keyRequest = 0;
  String? _keyError;
  bool _isSavingKey = false;
  final Set<int> _revokingKeys = {};

  AuthProvider(this._apiService) {
    _identity = _apiService.identity;
    _apiService.addListener(_sessionChanged);
    loadSavedAccounts();
  }

  void _sessionChanged() {
    if (_identity != _apiService.identity) {
      _identity = _apiService.identity;
      _keyRequest++;
      _heritageKeys = [];
      _savedAccounts = [];
      _keyError = null;
      _isLoadingKeys = false;
      _isSavingKey = false;
      _revokingKeys.clear();
      _errorMessage = null;
      loadSavedAccounts();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _apiService.removeListener(_sessionChanged);
    super.dispose();
  }

  bool get isAuthenticated => _apiService.isAuthenticated;
  bool get isPreviewMode => _apiService.isPreviewMode;
  User? get currentUser => _apiService.currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<HeritageKey> get heritageKeys => _heritageKeys;
  bool get isLoadingKeys => _isLoadingKeys;
  String? get keyError => _keyError;
  bool get isSavingKey => _isSavingKey;
  bool isRevokingKey(int id) => _revokingKeys.contains(id);
  List<SavedAccount> get savedAccounts => _savedAccounts;
  int? get invitedTreeId => _apiService.lastInvitedTreeId;
  int? get invitedPersonId => _apiService.lastInvitedPersonId;
  String? get invitedTreeName => _apiService.lastInvitedTreeName;

  Future<bool> login(String username, String password) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.login(username, password);
      if (!success) {
        _errorMessage =
            _apiService.lastAuthError ??
            'Unable to sign in. Check your username and password.';
      } else {
        await fetchHeritageKeys();
        await loadSavedAccounts();
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Sign-in error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? passwordConfirmation,
  }) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.register(
        username: username,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        firstName: firstName,
        lastName: lastName,
      );
      if (!success) {
        _errorMessage =
            _apiService.lastAuthError ?? 'Unable to create your account.';
      } else {
        await fetchHeritageKeys();
        await loadSavedAccounts();
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Registration error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithHeritageKey(String heritageKey) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.loginWithHeritageKey(heritageKey);
      if (!success) {
        _errorMessage =
            _apiService.lastAuthError ??
            'This personal key is invalid or unavailable.';
      } else {
        await fetchHeritageKeys();
        await loadSavedAccounts();
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Key sign-in error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchHeritageKeys() async {
    if (!isAuthenticated) return;
    final identity = _apiService.identity;
    final request = ++_keyRequest;
    _isLoadingKeys = true;
    _keyError = null;
    notifyListeners();
    try {
      final keys = await _apiService.getHeritageKeys();
      if (identity == _apiService.identity && request == _keyRequest) {
        _heritageKeys = keys;
      }
    } catch (e) {
      debugPrint('Error fetching heritage keys: $e');
      if (identity == _apiService.identity && request == _keyRequest) {
        _keyError =
            _apiService.lastError ?? 'Unable to load your keys. Try again.';
      }
    } finally {
      if (identity == _apiService.identity && request == _keyRequest) {
        _isLoadingKeys = false;
        notifyListeners();
      }
    }
  }

  Future<HeritageKey?> generateHeritageKey({
    String name = 'Personal key',
    String role = 'FAMILY_MEMBER',
  }) async {
    if (_isSavingKey) return null;
    final identity = _apiService.identity;
    _isSavingKey = true;
    _keyError = null;
    notifyListeners();
    try {
      final newKey = await _apiService.generateHeritageKey(
        name: name,
        role: role,
      );
      if (identity != _apiService.identity) return null;
      if (newKey != null) {
        _heritageKeys.insert(
          0,
          HeritageKey.fromJson({
            ...newKey.toJson(),
            'key': 'Hidden personal key #${newKey.id}',
          }),
        );
        notifyListeners();
      }
      if (newKey == null) {
        _keyError =
            _apiService.lastError ?? 'Unable to create this key. Try again.';
      }
      return newKey;
    } catch (e) {
      debugPrint('Error creating heritage key: $e');
      return null;
    } finally {
      if (identity == _apiService.identity) {
        _isSavingKey = false;
        notifyListeners();
      }
    }
  }

  Future<bool> revokeHeritageKey(int keyId) async {
    if (!_revokingKeys.add(keyId)) return false;
    final identity = _apiService.identity;
    _keyError = null;
    notifyListeners();
    try {
      final success = await _apiService.revokeHeritageKey(keyId);
      if (identity != _apiService.identity) return false;
      if (success) {
        _heritageKeys = _heritageKeys.map((k) {
          if (k.id == keyId) {
            return HeritageKey(
              id: k.id,
              key: k.key,
              userId: k.userId,
              username: k.username,
              name: k.name,
              role: k.role,
              isActive: false,
              expiresAt: k.expiresAt,
              lastUsedAt: k.lastUsedAt,
              usageCount: k.usageCount,
              createdAt: k.createdAt,
            );
          }
          return k;
        }).toList();
        notifyListeners();
      }
      if (!success) {
        _keyError =
            _apiService.lastError ?? 'Unable to revoke this key. Try again.';
      }
      return success;
    } catch (e) {
      debugPrint('Error revoking heritage key: $e');
      return false;
    } finally {
      if (identity == _apiService.identity) {
        _revokingKeys.remove(keyId);
        notifyListeners();
      }
    }
  }

  Future<void> demoLogin() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _apiService.demoLogin();
    await fetchHeritageKeys();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _apiService.logout();
    _heritageKeys = [];
    await LocalStorageService().setActiveAccount(null);
    await loadSavedAccounts();
    notifyListeners();
  }

  Future<void> loadSavedAccounts() async {
    final identity = _apiService.identity;
    final saved = await LocalStorageService().getSavedAccounts();
    if (identity == _apiService.identity) {
      _savedAccounts = saved;
      notifyListeners();
    }
  }

  Future<bool> switchToAccount(SavedAccount account) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.switchToAccount(account);
      if (success) {
        await fetchHeritageKeys();
        await loadSavedAccounts();
      } else {
        _errorMessage = 'Unable to switch accounts. Please sign in again.';
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Account switching error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> removeSavedAccount(String username) async {
    await LocalStorageService().removeAccount(username);
    await loadSavedAccounts();
  }
}
