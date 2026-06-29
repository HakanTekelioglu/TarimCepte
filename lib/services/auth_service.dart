import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
    String fullName, {
    String? city,
    String? district,
  });
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
    String phoneNumber,
    String password,
    String fullName, {
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

  String _normalizePhoneNumber(String phoneNumber) {
    var digits = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    if (digits.startsWith('90') && digits.length == 12) {
      return '+$digits';
    }

    if (digits.startsWith('9') && digits.length == 12) {
      return '+90${digits.substring(1)}';
    }

    if (digits.startsWith('0') && digits.length == 11) {
      return '+90${digits.substring(1)}';
    }

    if (digits.length == 10) {
      return '+90$digits';
    }

    return phoneNumber.trim();
  }

  Future<Map<String, dynamic>?> _findProfileByPhone(String phoneNumber) async {
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);

    final normalizedProfile =
        await _client
            .from('users')
            .select()
            .eq('phone_number', normalizedPhone)
            .maybeSingle();

    if (normalizedProfile != null || normalizedPhone == phoneNumber.trim()) {
      return normalizedProfile;
    }

    return _client
        .from('users')
        .select()
        .eq('phone_number', phoneNumber.trim())
        .maybeSingle();
  }

  @override
  Future<UserModel?> login(String phoneNumber, String password) async {
    late final AuthResponse authResponse;
    try {
      authResponse = await _client.auth.signInWithPassword(
        phone: _normalizePhoneNumber(phoneNumber),
        password: password,
      );
    } on AuthException catch (e) {
      final errorText = e.toString().toLowerCase();
      if (errorText.contains('phone_not_confirmed') ||
          errorText.contains('phone not confirmed')) {
        throw Exception(
          'Telefon dogrulanmamis. Supabase Authentication ayarlarinda Phone confirmation kapali olmali ya da SMS dogrulama tamamlanmali.',
        );
      }
      rethrow;
    }
    final authUser = authResponse.user;

    if (authUser == null) return null;

    final profile =
        await _client
            .from('users')
            .select()
            .eq('id', authUser.id)
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
    String fullName, {
    String? city,
    String? district,
  }) async {
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);
    final existingUser = await _findProfileByPhone(phoneNumber);

    if (existingUser != null) {
      throw Exception('Bu telefon numarası zaten kullanılıyor.');
    }

    late final AuthResponse authResponse;
    try {
      authResponse = await _client.auth.signUp(
        phone: normalizedPhone,
        password: password,
        data: {'full_name': fullName, 'name': fullName},
      );
    } on AuthException catch (e) {
      final errorText = e.toString().toLowerCase();
      if (errorText.contains('phone_provider_disabled')) {
        throw Exception(
          'Supabase Phone provider kapali. Authentication > Providers > Phone ayarini acmalisiniz.',
        );
      }
      rethrow;
    }
    final authUser = authResponse.user;

    if (authUser == null) {
      throw Exception('Kullanici olusturulamadi.');
    }

    final createdUser =
        await _client
            .from('users')
            .insert({
              'id': authUser.id,
              'phone_number': normalizedPhone,
              'password': password,
              'full_name': fullName,
              'commission_rate': 8.0,
              'is_admin': false,
              'created_at': DateTime.now().toIso8601String(),
              'city': city,
              'district': district,
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
    await _client.auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId =
        _client.auth.currentUser?.id ?? prefs.getString(_sessionUserIdKey);
    if (userId == null) return null;

    final profile =
        await _client.from('users').select().eq('id', userId).maybeSingle();

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
