import '../../models/user_model.dart';

/// Servis katmanindan arayuze guvenli bicimde gosterilebilecek auth hatasi.
final class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);

  @override
  String toString() => message;
}

abstract interface class IAuthService {
  Future<UserModel?> login(
    String phoneNumber,
    String password, {
    bool rememberMe = false,
  });

  Future<UserModel?> register(
    String phoneNumber,
    String password,
    String fullName, {
    String? email,
    String? city,
    String? district,
  });

  Future<void> logout();
  Future<UserModel?> getCurrentUser({bool isAppStartup = false});
  Future<void> markSessionActive();

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
