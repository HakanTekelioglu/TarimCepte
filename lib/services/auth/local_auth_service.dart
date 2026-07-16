import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../auth_session_policy.dart';
import '../contracts/auth_service_contract.dart';
import 'auth_session_store.dart';

/// Local Storage ile çalışan Auth servisi
class LocalAuthService implements IAuthService {
  static const String _usersKey = 'all_users';
  static const String _adminInitKey = 'admin_initialized';
  final AuthSessionStore _sessionStore;
  final Uuid _uuid = const Uuid();

  LocalAuthService({required AuthSessionStore sessionStore})
    : _sessionStore = sessionStore;

  String _envOrDefine(String key) {
    final envValue = dotenv.env[key];
    if (envValue != null && envValue.isNotEmpty) return envValue;
    return '';
  }

  String get _adminPhone => _envOrDefine('LOCAL_ADMIN_PHONE');
  String get _adminPassword => _envOrDefine('LOCAL_ADMIN_PASSWORD');
  String get _adminName {
    final value = _envOrDefine('LOCAL_ADMIN_NAME');
    return value.isEmpty ? 'Admin' : value;
  }

  /// Admin hesabını oluşturur (uygulama ilk açıldığında)
  Future<void> initializeAdmin() async {
    if (_adminPhone.isEmpty || _adminPassword.isEmpty) {
      // Admin bilgileri tanımlı değilse otomatik admin yaratma.
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final isInitialized = prefs.getBool(_adminInitKey) ?? false;

    if (!isInitialized) {
      final usersJson = prefs.getString(_usersKey);
      List<dynamic> users = [];
      if (usersJson != null) {
        users = jsonDecode(usersJson);
      }

      // Admin hesabı var mı kontrol ediyor
      bool adminExists = users.any(
        (u) => (u as Map<String, dynamic>)['phoneNumber'] == _adminPhone,
      );

      if (!adminExists) {
        final adminUser = UserModel(
          id: _uuid.v4(),
          phoneNumber: _adminPhone,
          fullName: _adminName,
          createdAt: DateTime.now(),
          isAdmin: true,
        );

        final adminJson = adminUser.toJson();
        adminJson['password'] = _adminPassword;
        users.add(adminJson);

        await prefs.setString(_usersKey, jsonEncode(users));
      }

      await prefs.setBool(_adminInitKey, true);
    }
  }

  @override
  Future<UserModel?> login(
    String phoneNumber,
    String password, {
    bool rememberMe = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Admin hesabını oluştur
    await initializeAdmin();

    final usersJson = prefs.getString(_usersKey);

    if (usersJson == null) return null;

    final List<dynamic> users = jsonDecode(usersJson);
    for (var userJson in users) {
      final user = userJson as Map<String, dynamic>;
      if (user['phoneNumber'] == phoneNumber && user['password'] == password) {
        final userModel = UserModel.fromJson(user);
        await _sessionStore.writeLocalUserJson(jsonEncode(userModel.toJson()));
        await _sessionStore.configureRememberMe(rememberMe);
        return userModel;
      }
    }
    return null;
  }

  @override
  Future<UserModel?> register(
    String phoneNumber,
    String password,
    String fullName, {
    String? email,
    String? city,
    String? district,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);

    List<dynamic> users = [];
    if (usersJson != null) {
      users = jsonDecode(usersJson);
      // Telefon numarası kontrolü
      for (var user in users) {
        if ((user as Map<String, dynamic>)['phoneNumber'] == phoneNumber) {
          throw Exception('Bu telefon numarası zaten kullanılıyor');
        }
      }
    }

    final newUser = UserModel(
      id: _uuid.v4(),
      phoneNumber: phoneNumber,
      email: email,
      fullName: fullName,
      createdAt: DateTime.now(),
      city: city,
      district: district,
    );

    final userJson = newUser.toJson();
    userJson['password'] =
        password; // Şifre sakla (gerçek uygulamada hash'lenmeli)
    users.add(userJson);

    await prefs.setString(_usersKey, jsonEncode(users));
    await _sessionStore.writeLocalUserJson(jsonEncode(newUser.toJson()));
    await _sessionStore.configureRememberMe(false);

    return newUser;
  }

  @override
  Future<void> logout() async {
    await _sessionStore.clear();
  }

  @override
  Future<UserModel?> getCurrentUser({bool isAppStartup = false}) async {
    final rememberMe = await _sessionStore.isRememberMeEnabled();

    if (isAppStartup && !rememberMe) {
      await logout();
      return null;
    }

    if (rememberMe &&
        AuthSessionPolicy.isExpired(await _sessionStore.readLastActivity())) {
      await logout();
      return null;
    }

    final userJson = await _sessionStore.readLocalUserJson();

    if (userJson == null) return null;
    await markSessionActive();
    return UserModel.fromJson(jsonDecode(userJson));
  }

  @override
  Future<void> markSessionActive() async {
    final rememberMe = await _sessionStore.isRememberMeEnabled();
    final hasSession = await _sessionStore.readLocalUserJson() != null;
    if (rememberMe && hasSession) {
      await _sessionStore.markActive();
    }
  }

  @override
  Future<UserModel?> verifyRegistrationCode(
    String email,
    String code, {
    required String phoneNumber,
    required String password,
    required String fullName,
    String? city,
    String? district,
  }) async {
    throw UnsupportedError(
      'Kayit dogrulama kodu yalnizca Supabase baglantisinda kullanilabilir.',
    );
  }

  @override
  Future<void> resendRegistrationCode(String email) async {
    throw UnsupportedError(
      'Kayit dogrulama kodu yalnizca Supabase baglantisinda kullanilabilir.',
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    throw UnsupportedError(
      'Şifre yenileme e-postası yalnızca Supabase bağlantısında kullanılabilir.',
    );
  }

  @override
  Future<void> verifyPasswordResetCode(String email, String code) async {
    throw UnsupportedError(
      'Şifre yenileme kodu yalnızca Supabase bağlantısında kullanılabilir.',
    );
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    throw UnsupportedError(
      'Şifre güncelleme yalnızca Supabase bağlantısında kullanılabilir.',
    );
  }

  @override
  Future<void> updateCommissionRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = await _sessionStore.readLocalUserJson();

    if (userJson == null) return;

    final user = UserModel.fromJson(jsonDecode(userJson));
    final updatedUser = user.copyWith(commissionRate: rate);

    await _sessionStore.writeLocalUserJson(jsonEncode(updatedUser.toJson()));

    // Kullanıcılar listesini de güncelle
    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null) {
      final List<dynamic> users = jsonDecode(usersJson);
      for (int i = 0; i < users.length; i++) {
        if ((users[i] as Map<String, dynamic>)['id'] == user.id) {
          users[i]['commissionRate'] = rate;
          break;
        }
      }
      await prefs.setString(_usersKey, jsonEncode(users));
    }
  }
}
