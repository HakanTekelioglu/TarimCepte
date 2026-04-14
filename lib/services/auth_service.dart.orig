import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'supabase_mapper.dart';

/// Kimlik doğrulama servisi
/// Firebase entegrasyonu için hazır altyapı
abstract class IAuthService {
  Future<UserModel?> login(String phoneNumber, String password);
  Future<UserModel?> register(
    String phoneNumber,
    String password,
    String fullName,
  );
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
  static const String _adminPhone = '+916637289596';
  static const String _adminPassword = 'admin123';
  static const String _adminName = 'Admin';

  /// Admin hesabını oluşturur (uygulama ilk açıldığında)
  Future<void> initializeAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final isInitialized = prefs.getBool(_adminInitKey) ?? false;

    if (!isInitialized) {
      final usersJson = prefs.getString(_usersKey);
      List<dynamic> users = [];
      if (usersJson != null) {
        users = jsonDecode(usersJson);
      }

      // Admin hesabı var mı kontrol ediyor
        bool adminExists = users.any((u) =>
          (u as Map<String, dynamic>)['phoneNumber'] == _adminPhone);

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
  Future<UserModel?> login(String phoneNumber, String password) async {
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
        await prefs.setString(_userKey, jsonEncode(userModel.toJson()));
        return userModel;
      }
    }
    return null;
  }

  @override
  Future<UserModel?> register(
      String phoneNumber, String password, String fullName) async {
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

/// Supabase ile çalışan Auth servisi
class SupabaseAuthService implements IAuthService {
  final SupabaseClient _client;
  static const String _sessionUserIdKey = 'supabase_session_user_id';

  SupabaseAuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<UserModel?> login(String phoneNumber, String password) async {
    final profile = await _client
        .from('users')
        .select()
        .eq('phone_number', phoneNumber)
        .eq('password', password)
        .maybeSingle();

    if (profile == null) return null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionUserIdKey, profile['id'] as String);

    return userFromDbMap(profile);
  }

  @override
  Future<UserModel?> register(
    String phoneNumber,
    String password,
    String fullName,
  ) async {
    final existingUser = await _client
        .from('users')
        .select('id')
        .eq('phone_number', phoneNumber)
        .maybeSingle();

    if (existingUser != null) {
      throw Exception('Bu telefon numarası zaten kullanılıyor.');
    }

    final createdUser = await _client
        .from('users')
        .insert({
          'phone_number': phoneNumber,
          'password': password,
          'full_name': fullName,
          'commission_rate': 8.0,
          'is_admin': false,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionUserIdKey, createdUser['id'] as String);

    return userFromDbMap(createdUser);
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionUserIdKey);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_sessionUserIdKey);
    if (userId == null) return null;

    final profile = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (profile == null) {
      await prefs.remove(_sessionUserIdKey);
      return null;
    }

    return userFromDbMap(profile);
  }

  @override
  Future<void> updateCommissionRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_sessionUserIdKey);
    if (userId == null) return;

    await _client
        .from('users')
        .update({'commission_rate': rate})
        .eq('id', userId);
  }
}
