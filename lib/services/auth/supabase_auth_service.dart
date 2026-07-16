import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/auth/turkish_phone_number.dart';
import '../../models/models.dart';
import '../auth_session_policy.dart';
import '../contracts/auth_service_contract.dart';
import '../supabase_mapper.dart';
import 'auth_session_store.dart';

/// Supabase ile çalışan Auth servisi
class SupabaseAuthService implements IAuthService {
  final SupabaseClient _client;
  final AuthSessionStore _sessionStore;

  SupabaseAuthService({
    required AuthSessionStore sessionStore,
    SupabaseClient? client,
  }) : _sessionStore = sessionStore,
       _client = client ?? Supabase.instance.client;

  Future<Map<String, dynamic>?> _findProfileByPhone(String phoneNumber) async {
    for (final candidate in TurkishPhoneNumber.lookupCandidates(phoneNumber)) {
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

  Future<String?> _findLoginEmailByPhone(String phoneNumber) async {
    final candidates = TurkishPhoneNumber.lookupCandidates(phoneNumber);

    try {
      final result = await _client.rpc<String?>(
        'login_email_for_phone',
        params: {'phone_candidates': candidates},
      );
      return _normalizeEmail(result);
    } on PostgrestException catch (e) {
      // Eski kurulumlarda RPC henuz olmayabilir. Telefon tabanli eski Auth
      // hesaplari asagidaki signInWithPassword fallback'i ile calismaya devam eder.
      if (e.code == 'PGRST202' || e.code == '42883') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<UserModel?> login(
    String identifier,
    String password, {
    bool rememberMe = false,
  }) async {
    AuthResponse? authResponse;
    AuthException? lastAuthException;
    final normalizedIdentifier = identifier.trim();
    final isEmailLogin = normalizedIdentifier.contains('@');
    final profileByPhone =
        isEmailLogin ? null : await _findProfileByPhone(normalizedIdentifier);
    final email =
        isEmailLogin
            ? _normalizeEmail(normalizedIdentifier)
            : _normalizeEmail(profileByPhone?['email'] as String?) ??
                await _findLoginEmailByPhone(normalizedIdentifier);

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

    if (authResponse == null && !isEmailLogin) {
      for (final candidate in TurkishPhoneNumber.lookupCandidates(
        normalizedIdentifier,
      )) {
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
        if (_isInvalidCredentials(lastAuthException)) {
          throw const AuthServiceException(
            'Telefon/e-posta veya şifre hatalı.',
          );
        }
        throw lastAuthException;
      }
      return null;
    }
    final authUser = authResponse.user;

    if (authUser == null) return null;

    var profile =
        await _client
            .from('users')
            .select()
            .eq('id', authUser.id)
            .maybeSingle();

    if (profile == null) {
      throw const AuthServiceException(
        'Şifre doğrulandı ancak kullanıcı profili Auth hesabıyla eşleşmiyor.',
      );
    }
    var resolvedProfile = profile;

    if (profileByPhone != null && profileByPhone['id'] != authUser.id) {
      throw const AuthServiceException(
        'Telefon numarası farklı bir Auth hesabına bağlı görünüyor.',
      );
    }

    final authEmail = _normalizeEmail(authUser.email);
    final profileEmail = _normalizeEmail(resolvedProfile['email'] as String?);
    if (authEmail != null && profileEmail != authEmail) {
      try {
        resolvedProfile =
            await _client
                .from('users')
                .update({'email': authEmail})
                .eq('id', authUser.id)
                .select()
                .single();
      } on PostgrestException {
        // Profil guncelleme politikasi izin vermese bile dogrulanmis girisi bozma.
      }
    }

    await _sessionStore.writeSupabaseUserId(resolvedProfile['id'] as String);
    await _sessionStore.configureRememberMe(rememberMe);

    return userFromDbMap(resolvedProfile);
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
    final normalizedPhone = TurkishPhoneNumber.normalize(phoneNumber);
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
    final normalizedPhone = TurkishPhoneNumber.normalize(phoneNumber);

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
      await _sessionStore.writeSupabaseUserId(existingProfile['id'] as String);
      await _sessionStore.configureRememberMe(false);
      return userFromDbMap(existingProfile);
    }

    final createdUser =
        await _client
            .from('users')
            .insert({
              'id': authUser.id,
              'phone_number': normalizedPhone,
              'email': normalizedEmail,
              'full_name': fullName,
              'commission_rate': 8.0,
              'is_admin': false,
              'created_at': DateTime.now().toIso8601String(),
              'city': city,
              'district': district,
            })
            .select()
            .single();

    await _sessionStore.writeSupabaseUserId(createdUser['id'] as String);
    await _sessionStore.configureRememberMe(false);

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

  bool _isInvalidCredentials(AuthException exception) {
    return exception.code == 'invalid_credentials' ||
        exception.message.toLowerCase().contains('invalid login credentials');
  }

  @override
  Future<void> logout() async {
    await _sessionStore.clear();
    if (_client.auth.currentUser == null) return;
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Yerel oturum temizlendi; ağ hatası çıkışı engellememeli.
    }
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

    final userId =
        _client.auth.currentUser?.id ??
        await _sessionStore.readSupabaseUserId();
    if (userId == null) return null;

    final profile =
        await _client.from('users').select().eq('id', userId).maybeSingle();

    if (profile == null) {
      await logout();
      return null;
    }

    await markSessionActive();
    return userFromDbMap(profile);
  }

  @override
  Future<void> markSessionActive() async {
    final hasSession =
        _client.auth.currentUser != null ||
        await _sessionStore.readSupabaseUserId() != null;
    if (await _sessionStore.isRememberMeEnabled() && hasSession) {
      await _sessionStore.markActive();
    }
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
    } on AuthException catch (e) {
      throw Exception('Şifre güncellenemedi: ${e.message}');
    }
  }

  @override
  Future<void> updateCommissionRate(double rate) async {
    final userId = await _sessionStore.readSupabaseUserId();
    if (userId == null) return;

    await _client
        .from('users')
        .update({'commission_rate': rate})
        .eq('id', userId);
  }
}
