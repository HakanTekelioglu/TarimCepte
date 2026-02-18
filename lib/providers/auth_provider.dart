import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Kimlik doğrulama state yönetimi
class AuthProvider extends ChangeNotifier {
  final IAuthService _authService;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthProvider({IAuthService? authService})
      : _authService = authService ?? LocalAuthService();

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get error => _error;

  /// Uygulama başlangıcında mevcut kullanıcıyı kontrol et
  Future<void> checkCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUser();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Giriş yap
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(email, password);
      if (_currentUser == null) {
        _error = 'E-posta veya şifre hatalı';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return _currentUser != null;
  }

  /// Kayıt ol
  Future<bool> register(String email, String password, String fullName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.register(email, password, fullName);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return _currentUser != null;
  }

  /// Çıkış yap
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  /// Komisyon oranını güncelle
  Future<void> updateCommissionRate(double rate) async {
    if (_currentUser == null) return;

    try {
      await _authService.updateCommissionRate(rate);
      _currentUser = _currentUser!.copyWith(commissionRate: rate);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
