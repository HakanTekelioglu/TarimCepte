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
  Future<void> checkCurrentUser({bool isAppStartup = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUser(
        isAppStartup: isAppStartup,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Giriş yap
  Future<bool> login(
    String phoneNumber,
    String password, {
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(
        phoneNumber,
        password,
        rememberMe: rememberMe,
      );
      if (_currentUser == null) {
        _error = 'Telefon numarası veya şifre hatalı';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return _currentUser != null;
  }

  /// Kayıt ol
  Future<bool> register(
    String phoneNumber,
    String password,
    String fullName, {
    String? email,
    String? city,
    String? district,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.register(
        phoneNumber,
        password,
        fullName,
        email: email,
        city: city,
        district: district,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> verifyRegistrationCode(
    String email,
    String code, {
    required String phoneNumber,
    required String password,
    required String fullName,
    String? city,
    String? district,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.verifyRegistrationCode(
        email,
        code,
        phoneNumber: phoneNumber,
        password: password,
        fullName: fullName,
        city: city,
        district: district,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return _currentUser != null;
  }

  Future<bool> resendRegistrationCode(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resendRegistrationCode(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyPasswordResetCode(String email, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.verifyPasswordResetCode(email, code);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updatePassword(newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Çıkış yap
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> markSessionActive() async {
    if (_currentUser == null) return;
    await _authService.markSessionActive();
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
