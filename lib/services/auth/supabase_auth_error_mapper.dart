import 'package:supabase_flutter/supabase_flutter.dart';

import '../contracts/auth_service_contract.dart';

/// Supabase Auth hatalarinin teknik ayrintilarini arayuze sizdirmadan
/// kullanicinin uygulayabilecegi mesajlara donusturur.
final class SupabaseAuthErrorMapper {
  const SupabaseAuthErrorMapper._();

  static AuthServiceException registration(AuthException exception) {
    final details = _details(exception);

    if (_isRateLimited(exception, details)) {
      return const AuthServiceException(
        'Çok kısa sürede fazla doğrulama e-postası istendi. '
        'Lütfen bir süre sonra tekrar deneyin.',
      );
    }

    if (details.contains('email_provider_disabled')) {
      return const AuthServiceException(
        'E-posta ile kayıt şu anda kullanılamıyor. Lütfen destek ekibiyle '
        'iletişime geçin.',
      );
    }

    if (details.contains('email address not authorized') ||
        details.contains('email_address_not_authorized')) {
      return const AuthServiceException(
        'Bu adrese doğrulama e-postası gönderilemiyor. Lütfen başka bir '
        'e-posta adresi deneyin veya destek ekibiyle iletişime geçin.',
      );
    }

    if (details.contains('user_already_exists') ||
        details.contains('user already registered')) {
      return const AuthServiceException(
        'Bu e-posta adresiyle daha önce kayıt oluşturulmuş.',
      );
    }

    if (details.contains('weak_password') ||
        exception is AuthWeakPasswordException) {
      return const AuthServiceException(
        'Şifre güvenlik koşullarını karşılamıyor. Lütfen daha güçlü bir '
        'şifre belirleyin.',
      );
    }

    if (_isEmailDeliveryFailure(exception, details)) {
      return const AuthServiceException(
        'Doğrulama e-postası şu anda gönderilemiyor. Lütfen biraz sonra '
        'tekrar deneyin. Sorun sürerse destek ekibiyle iletişime geçin.',
      );
    }

    if (exception is AuthRetryableFetchException) {
      return const AuthServiceException(
        'Kayıt servisine şu anda ulaşılamıyor. İnternet bağlantınızı kontrol '
        'edip biraz sonra tekrar deneyin.',
      );
    }

    return const AuthServiceException(
      'Kayıt tamamlanamadı. Lütfen bilgilerinizi kontrol edip tekrar deneyin.',
    );
  }

  static AuthServiceException resendConfirmation(AuthException exception) {
    final details = _details(exception);

    if (_isRateLimited(exception, details)) {
      return const AuthServiceException(
        'Çok kısa sürede fazla doğrulama e-postası istendi. '
        'Lütfen bir süre sonra tekrar deneyin.',
      );
    }

    if (_isEmailDeliveryFailure(exception, details)) {
      return const AuthServiceException(
        'Doğrulama e-postası şu anda gönderilemiyor. Lütfen biraz sonra '
        'tekrar deneyin. Sorun sürerse destek ekibiyle iletişime geçin.',
      );
    }

    if (exception is AuthRetryableFetchException) {
      return const AuthServiceException(
        'E-posta servisine şu anda ulaşılamıyor. İnternet bağlantınızı '
        'kontrol edip biraz sonra tekrar deneyin.',
      );
    }

    return const AuthServiceException(
      'Doğrulama kodu tekrar gönderilemedi. Lütfen biraz sonra yeniden deneyin.',
    );
  }

  static String _details(AuthException exception) {
    return '${exception.code ?? ''} ${exception.message}'.toLowerCase();
  }

  static bool _isRateLimited(AuthException exception, String details) {
    return exception.statusCode == '429' ||
        details.contains('too many requests') ||
        details.contains('email_rate_limit_exceeded') ||
        details.contains('over_email_send_rate_limit');
  }

  static bool _isEmailDeliveryFailure(AuthException exception, String details) {
    final mentionsEmailSending =
        details.contains('error sending confirmation email') ||
        details.contains('error sending email') ||
        details.contains('smtp');

    return mentionsEmailSending &&
        (exception.statusCode == '500' ||
            details.contains('unexpected_failure') ||
            exception is AuthRetryableFetchException);
  }
}
