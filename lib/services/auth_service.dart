import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

/// Kimlik doğrulama servisi
/// Firebase entegrasyonu için hazır altyapı
abstract class IAuthService {
  Future<UserModel?> login(String email, String password);
  Future<UserModel?> register(String email, String password, String fullName);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<void> updateCommissionRate(double rate);
}

/// Local Storage ile çalışan Auth servisi
/// Firebase entegrasyonu yapıldığında bu sınıf değiştirilebilir
class LocalAuthService implements IAuthService {
  static const String _userKey = 'current_user';
  static const String _usersKey = 'all_users';
  static const String _adminInitKey = 'admin_initialized';
  final Uuid _uuid = const Uuid();

  // Admin hesap bilgileri
  static const String _adminEmail = 'admin@halfiyat.com';
  static const String _adminPassword = 'admin123';
  static const String _adminName = 'Admin';

  /// Admin hesabını oluştur (uygulama ilk açıldığında)
  Future<void> initializeAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final isInitialized = prefs.getBool(_adminInitKey) ?? false;

    if (!isInitialized) {
      final usersJson = prefs.getString(_usersKey);
      List<dynamic> users = [];
      if (usersJson != null) {
        users = jsonDecode(usersJson);
      }

      // Admin hesabı var mı kontrol et
      bool adminExists = users.any((u) => (u as Map<String, dynamic>)['email'] == _adminEmail);

      if (!adminExists) {
        final adminUser = UserModel(
          id: _uuid.v4(),
          email: _adminEmail,
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
  Future<UserModel?> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Admin hesabını oluştur
    await initializeAdmin();
    
    final usersJson = prefs.getString(_usersKey);

    if (usersJson == null) return null;

    final List<dynamic> users = jsonDecode(usersJson);
    for (var userJson in users) {
      final user = userJson as Map<String, dynamic>;
      if (user['email'] == email && user['password'] == password) {
        final userModel = UserModel.fromJson(user);
        await prefs.setString(_userKey, jsonEncode(userModel.toJson()));
        return userModel;
      }
    }
    return null;
  }

  @override
  Future<UserModel?> register(
      String email, String password, String fullName) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);

    List<dynamic> users = [];
    if (usersJson != null) {
      users = jsonDecode(usersJson);
      // E-posta kontrolü
      for (var user in users) {
        if ((user as Map<String, dynamic>)['email'] == email) {
          throw Exception('Bu e-posta adresi zaten kullanılıyor');
        }
      }
    }

    final newUser = UserModel(
      id: _uuid.v4(),
      email: email,
      fullName: fullName,
      createdAt: DateTime.now(),
    );

    final userJson = newUser.toJson();
    userJson['password'] = password; // Şifre sakla (gerçek uygulamada hash'lenmeli)
    users.add(userJson);

    await prefs.setString(_usersKey, jsonEncode(users));
    await prefs.setString(_userKey, jsonEncode(newUser.toJson()));

    return newUser;
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson == null) return null;
    return UserModel.fromJson(jsonDecode(userJson));
  }

  @override
  Future<void> updateCommissionRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson == null) return;

    final user = UserModel.fromJson(jsonDecode(userJson));
    final updatedUser = user.copyWith(commissionRate: rate);

    await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));

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
