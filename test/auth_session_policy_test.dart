import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hal_fiyat/services/auth_session_policy.dart';
import 'package:hal_fiyat/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AuthSessionPolicy', () {
    final now = DateTime.utc(2026, 7, 14, 12);

    test('keeps a remembered session before 48 hours', () {
      final lastActivity = now.subtract(const Duration(hours: 47, minutes: 59));

      expect(
        AuthSessionPolicy.isExpired(lastActivity.toIso8601String(), now: now),
        isFalse,
      );
    });

    test('expires a remembered session at 48 hours', () {
      final lastActivity = now.subtract(const Duration(hours: 48));

      expect(
        AuthSessionPolicy.isExpired(lastActivity.toIso8601String(), now: now),
        isTrue,
      );
    });

    test('expires a session when its activity timestamp is missing', () {
      expect(AuthSessionPolicy.isExpired(null, now: now), isTrue);
    });
  });

  group('LocalAuthService remembered session', () {
    const phoneNumber = '+905551112233';
    const password = 'secret123';

    setUp(() {
      dotenv.testLoad(fileInput: '');
      SharedPreferences.setMockInitialValues({
        'all_users': jsonEncode([
          {
            'id': 'user-1',
            'phoneNumber': phoneNumber,
            'fullName': 'Test User',
            'createdAt': DateTime.utc(2026, 7, 14).toIso8601String(),
            'password': password,
          },
        ]),
      });
    });

    test('restores and renews a remembered session before 48 hours', () async {
      final service = LocalAuthService();
      final user = await service.login(phoneNumber, password, rememberMe: true);
      final prefs = await SharedPreferences.getInstance();
      final previousActivity = DateTime.now().toUtc().subtract(
        const Duration(hours: 47),
      );
      await prefs.setString(
        'auth_last_activity_at',
        previousActivity.toIso8601String(),
      );

      final restored = await service.getCurrentUser(isAppStartup: true);
      final renewedActivity = DateTime.parse(
        prefs.getString('auth_last_activity_at')!,
      );

      expect(user, isNotNull);
      expect(restored?.id, 'user-1');
      expect(prefs.getBool('auth_remember_me'), isTrue);
      expect(renewedActivity.isAfter(previousActivity), isTrue);
    });

    test('clears a remembered session after 48 hours', () async {
      final service = LocalAuthService();
      await service.login(phoneNumber, password, rememberMe: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'auth_last_activity_at',
        DateTime.now()
            .toUtc()
            .subtract(const Duration(hours: 49))
            .toIso8601String(),
      );

      final restored = await service.getCurrentUser(isAppStartup: true);

      expect(restored, isNull);
      expect(prefs.containsKey('current_user'), isFalse);
      expect(prefs.containsKey('auth_remember_me'), isFalse);
    });

    test('does not restore an unremembered session after restart', () async {
      final service = LocalAuthService();
      await service.login(phoneNumber, password);

      expect(await service.getCurrentUser(), isNotNull);
      expect(await service.getCurrentUser(isAppStartup: true), isNull);
    });
  });
}
