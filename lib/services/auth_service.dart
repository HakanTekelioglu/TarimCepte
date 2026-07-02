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
    String? email,
    String? city,
    String? district,
  });
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<UserModel?> verifyRegistrationCode(
    String email,
    String code, {
    required String phoneNumber,
    required String password,
    required String fullName,
    String? city,
    String? district,
  });
  Future<void> resendRegistrationCode(String email);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> verifyPasswordResetCode(String email, String code);
  Future<void> updatePassword(String newPassword);
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

  List<String> _phoneLookupCandidates(String phoneNumber) {
    final candidates = <String>{};
    final trimmed = phoneNumber.trim();
    final normalized = _normalizePhoneNumber(trimmed);
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');

    void add(String value) {
      if (value.trim().isNotEmpty) {
        candidates.add(value.trim());
      }
    }

    add(normalized);
    add(trimmed);

    var plainDigits = digits;
    if (plainDigits.startsWith('00')) {
      plainDigits = plainDigits.substring(2);
    }

    if (plainDigits.startsWith('90') && plainDigits.length == 12) {
      final local = plainDigits.substring(2);
      add('+90$local');
      add('+9$local');
    } else if (plainDigits.startsWith('0') && plainDigits.length == 11) {
      final local = plainDigits.substring(1);
      add('+90$local');
      add('+9$local');
    } else if (plainDigits.length == 10) {
      add('+90$plainDigits');
      add('+9$plainDigits');
    } else if (plainDigits.startsWith('9') && plainDigits.length == 11) {
      final local = plainDigits.substring(1);
      add('+$plainDigits');
      add('+90$local');
      add('+9$local');
    }

    return candidates.toList();
  }

  Future<Map<String, dynamic>?> _findProfileByPhone(String phoneNumber) async {
    for (final candidate in _phoneLookupCandidates(phoneNumber)) {
      final profile =
          await _client
              .from('users')
              .select()
              .eq('phone_number', candidate)
              .maybeSingle();

      if (profile != null) {
        return profile;
      }
    }

    return null;
  }

  Future<Map<String, dynamic>?> _findProfileByEmail(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) return null;

    return await _client
        .from('users')
        .select()
        .eq('email', normalizedEmail)
        .maybeSingle();
  }

  @override
  Future<UserModel?> login(String phoneNumber, String password) async {
    AuthResponse? authResponse;
    AuthException? lastAuthException;
    final profileByPhone = await _findProfileByPhone(phoneNumber);
    final email = _normalizeEmail(profileByPhone?['email'] as String?);

    if (email != null) {
      try {
        authResponse = await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } on AuthException catch (e) {
        lastAuthException = e;
      }
    }

    if (authResponse == null) {
      for (final candidate in _phoneLookupCandidates(phoneNumber)) {
        try {
          authResponse = await _client.auth.signInWithPassword(
            phone: candidate,
            password: password,
          );
          break;
        } on AuthException catch (e) {
          lastAuthException = e;
          final errorText = e.toString().toLowerCase();
          if (errorText.contains('phone_not_confirmed') ||
              errorText.contains('phone not confirmed')) {
            throw Exception(
              'Telefon dogrulanmamis. Supabase Authentication ayarlarinda Phone confirmation kapali olmali ya da SMS dogrulama tamamlanmali.',
            );
          }
        }
      }
    }

    if (authResponse == null) {
      if (lastAuthException != null) {
        throw lastAuthException;
      }
      return null;
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
    String? email,
    String? city,
    String? district,
  }) async {
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) {
      throw Exception('E-posta adresi giriniz.');
    }

    final existingUser = await _findProfileByPhone(phoneNumber);

    if (existingUser != null) {
      throw Exception('Bu telefon numarası zaten kullanılıyor.');
    }

    final existingEmail = await _findProfileByEmail(normalizedEmail);
    if (existingEmail != null) {
      throw Exception('Bu e-posta adresi zaten kullanılıyor.');
    }

    late final AuthResponse authResponse;
    try {
      authResponse = await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'full_name': fullName,
          'name': fullName,
          'phone_number': normalizedPhone,
        },
      );
    } on AuthException catch (e) {
      final errorText = e.toString().toLowerCase();
      if (errorText.contains('email_provider_disabled')) {
        throw Exception(
          'Supabase Email provider kapali. Authentication > Providers > Email ayarini acmalisiniz.',
        );
      }
      rethrow;
    }
    final authUser = authResponse.user;

    if (authUser == null) {
      throw Exception('Kullanici olusturulamadi.');
    }

    if (authResponse.session != null) {
      await _client.auth.signOut();
      throw Exception(
        'Supabase e-posta dogrulamasi kapali gorunuyor. Kod ile kayit onayi icin Dashboard > Authentication > Providers > Email alaninda Confirm email ayarini acin.',
      );
    }

    return null;
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
    final normalizedEmail = _normalizeEmail(email);
    final normalizedCode = code.trim();
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);

    if (normalizedEmail == null) {
      throw Exception('E-posta adresi giriniz.');
    }

    if (normalizedCode.isEmpty) {
      throw Exception('Dogrulama kodunu giriniz.');
    }

    late final AuthResponse authResponse;
    try {
      authResponse = await _client.auth.verifyOTP(
        email: normalizedEmail,
        token: normalizedCode,
        type: OtpType.signup,
      );
    } on AuthException catch (e) {
      throw Exception('Kayit dogrulama kodu onaylanamadi: ${e.message}');
    }

    final authUser = authResponse.user;
    if (authUser == null) {
      throw Exception('Kullanici dogrulanamadi.');
    }

    final existingProfile =
        await _client
            .from('users')
            .select()
            .eq('id', authUser.id)
            .maybeSingle();

    if (existingProfile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionUserIdKey, existingProfile['id'] as String);
      return userFromDbMap(existingProfile);
    }

    final createdUser =
        await _client
            .from('users')
            .insert({
              'id': authUser.id,
              'phone_number': normalizedPhone,
              'email': normalizedEmail,
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
  Future<void> resendRegistrationCode(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) {
      throw Exception('E-posta adresi giriniz.');
    }

    try {
      await _client.auth.resend(email: normalizedEmail, type: OtpType.signup);
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();
      if (e.statusCode == '429' || message.contains('too many requests')) {
        throw Exception(
          'Supabase saatlik e-posta limiti doldu. Lutfen yaklasik 1 saat sonra tekrar deneyin veya Supabase SMTP ayari yapin.',
        );
      }
      throw Exception('Dogrulama kodu tekrar gonderilemedi: ${e.message}');
    }
  }

  String? _normalizeEmail(String? email) {
    final trimmed = email?.trim().toLowerCase();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
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
  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) {
      throw Exception('E-posta adresi giriniz.');
    }

    try {
      await _client.auth.resetPasswordForEmail(normalizedEmail);
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();
      if (e.statusCode == '429' || message.contains('too many requests')) {
        throw Exception(
          'Supabase saatlik e-posta limiti doldu. Yerleşik e-posta sağlayıcıda saatte en fazla 2 email gönderilebilir. Lütfen yaklaşık 1 saat sonra tekrar deneyin veya Supabase SMTP ayarı yapın.',
        );
      }
      if (e.statusCode == '500' ||
          message.contains('error sending recovery email') ||
          message.contains('error sending email')) {
        throw Exception(
          'Şifre yenileme e-postası gönderilemedi. Supabase, SMTP sağlayıcısına e-posta gönderirken hata aldı. Brevo kullanıyorsanız Supabase sunucu IP adresini Brevo > Security > Authorized IPs alanında onaylayın veya SMTP IP kısıtlamasını düzenleyin.',
        );
      }
      throw Exception('Şifre yenileme e-postası gönderilemedi: ${e.message}');
    }
  }

  @override
  Future<void> verifyPasswordResetCode(String email, String code) async {
    final normalizedEmail = _normalizeEmail(email);
    final normalizedCode = code.trim();

    if (normalizedEmail == null) {
      throw Exception('E-posta adresi giriniz.');
    }

    if (normalizedCode.isEmpty) {
      throw Exception('Yenileme kodunu giriniz.');
    }

    try {
      await _client.auth.verifyOTP(
        email: normalizedEmail,
        token: normalizedCode,
        type: OtpType.recovery,
      );
    } on AuthException catch (e) {
      throw Exception('Yenileme kodu doğrulanamadı: ${e.message}');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    if (newPassword.length < 6) {
      throw Exception('Şifre en az 6 karakter olmalı.');
    }

    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        await _client
            .from('users')
            .update({'password': newPassword})
            .eq('id', userId);
      }
    } on AuthException catch (e) {
      throw Exception('Şifre güncellenemedi: ${e.message}');
    } catch (e) {
      throw Exception(
        'Şifre güncellendi ancak kullanıcı tablosu güncellenemedi: $e',
      );
    }
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
