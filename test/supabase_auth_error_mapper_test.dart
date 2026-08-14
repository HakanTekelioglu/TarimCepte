import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tarimcepte/services/auth/supabase_auth_error_mapper.dart';

void main() {
  group('SupabaseAuthErrorMapper.registration', () {
    test('500 confirmation email hatasini teknik ayrinti olmadan gosterir', () {
      final exception = AuthRetryableFetchException(
        message: 'Error sending confirmation email',
        statusCode: '500',
      );

      final result = SupabaseAuthErrorMapper.registration(exception);

      expect(
        result.message,
        'Doğrulama e-postası şu anda gönderilemiyor. Lütfen biraz sonra '
        'tekrar deneyin. Sorun sürerse destek ekibiyle iletişime geçin.',
      );
      expect(result.message, isNot(contains('AuthRetryableFetchException')));
      expect(result.message, isNot(contains('statusCode')));
    });

    test('e-posta limitini ayri bir mesaja donusturur', () {
      final exception = AuthApiException(
        'Email rate limit exceeded',
        statusCode: '429',
        code: 'over_email_send_rate_limit',
      );

      final result = SupabaseAuthErrorMapper.registration(exception);

      expect(result.message, contains('fazla doğrulama e-postası'));
    });

    test('ag kaynakli retryable hatayi SMTP hatasi olarak tanimlamaz', () {
      final exception = AuthRetryableFetchException(
        message: 'SocketException: Failed host lookup',
      );

      final result = SupabaseAuthErrorMapper.registration(exception);

      expect(result.message, contains('İnternet bağlantınızı'));
      expect(result.message, isNot(contains('Doğrulama e-postası')));
    });
  });
}
