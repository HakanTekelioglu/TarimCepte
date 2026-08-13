import 'package:flutter_test/flutter_test.dart';
import 'package:tarimcepte/models/models.dart';
import 'package:tarimcepte/providers/auth_provider.dart';
import 'package:tarimcepte/services/contracts/auth_service_contract.dart';

void main() {
  test('giris hatasini teknik Supabase metni olmadan gosterir', () async {
    final provider = AuthProvider(authService: _InvalidCredentialsService());

    final success = await provider.login('+905551112233', 'wrong-password');

    expect(success, isFalse);
    expect(provider.error, 'Telefon/e-posta veya şifre hatalı.');
    expect(provider.error, isNot(contains('AuthApiException')));
    expect(provider.error, isNot(contains('invalid_credentials')));
  });
}

final class _InvalidCredentialsService extends Fake implements IAuthService {
  @override
  Future<UserModel?> login(
    String phoneNumber,
    String password, {
    bool rememberMe = false,
  }) {
    throw const AuthServiceException('Telefon/e-posta veya şifre hatalı.');
  }
}
