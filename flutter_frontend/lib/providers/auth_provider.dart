import 'package:flutter/material.dart';
import '../models/heritage_key.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  bool _isLoading = false;
  String? _errorMessage;
  List<HeritageKey> _heritageKeys = [];
  bool _isLoadingKeys = false;

  AuthProvider(this._apiService);

  bool get isAuthenticated => _apiService.isAuthenticated;
  User? get currentUser => _apiService.currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<HeritageKey> get heritageKeys => _heritageKeys;
  bool get isLoadingKeys => _isLoadingKeys;
  int? get invitedTreeId => _apiService.lastInvitedTreeId;
  int? get invitedPersonId => _apiService.lastInvitedPersonId;
  String? get invitedTreeName => _apiService.lastInvitedTreeName;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.login(username, password);
      if (!success) {
        _errorMessage = 'Identifiants invalides. Veuillez vérifier votre nom d\'utilisateur et mot de passe.';
      } else {
        await fetchHeritageKeys();
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Erreur de connexion : $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithHeritageKey(String heritageKey) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.loginWithHeritageKey(heritageKey);
      if (!success) {
        _errorMessage = _apiService.lastAuthError ?? 'Clé d\'Héritage invalide ou introuvable dans la base dynastique.';
      } else {
        await fetchHeritageKeys();
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Erreur d\'authentification par clé : $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchHeritageKeys() async {
    if (!isAuthenticated) return;
    _isLoadingKeys = true;
    notifyListeners();
    try {
      _heritageKeys = await _apiService.getHeritageKeys();
    } catch (e) {
      debugPrint('Error fetching heritage keys: $e');
    } finally {
      _isLoadingKeys = false;
      notifyListeners();
    }
  }

  Future<HeritageKey?> generateHeritageKey({String name = 'Clé Royale', String role = 'FAMILY_MEMBER'}) async {
    try {
      final newKey = await _apiService.generateHeritageKey(name: name, role: role);
      if (newKey != null) {
        _heritageKeys.insert(0, newKey);
        notifyListeners();
      }
      return newKey;
    } catch (e) {
      debugPrint('Error creating heritage key: $e');
      return null;
    }
  }

  Future<bool> revokeHeritageKey(int keyId) async {
    try {
      final success = await _apiService.revokeHeritageKey(keyId);
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
      return success;
    } catch (e) {
      debugPrint('Error revoking heritage key: $e');
      return false;
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
    notifyListeners();
  }
}
