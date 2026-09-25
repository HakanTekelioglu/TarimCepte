import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tarimcepte/models/models.dart';
import 'package:tarimcepte/providers/providers.dart';
import 'package:tarimcepte/screens/settings_screen.dart';
import 'package:tarimcepte/services/contracts/auth_service_contract.dart';
import 'package:tarimcepte/services/contracts/season_service_contract.dart';

void main() {
  testWidgets('active season rate takes priority and save order stays atomic', (
    tester,
  ) async {
    final calls = <String>[];
    final user = UserModel(
      id: 'user-1',
      phoneNumber: '05000000000',
      fullName: 'Test Kullanıcı',
      commissionRate: 13,
      createdAt: DateTime(2026),
    );
    final auth = AuthProvider(
      authService: _FakeAuthService(user: user, calls: calls),
    );
    final season = SeasonProvider(
      seasonService: _FakeSeasonService(userId: user.id, calls: calls),
    );

    await auth.checkCurrentUser();
    await season.createSeason(user.id, '2026-2027 sezonu', 10);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: season),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '10.0');

    await tester.enterText(find.byType(TextField), '12.0');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(calls, ['season:12.0', 'user:12.0']);
    expect(auth.currentUser?.commissionRate, 12);
    expect(season.activeSeason?.commissionRate, 12);
  });
}

class _FakeAuthService implements IAuthService {
  final UserModel user;
  final List<String> calls;

  _FakeAuthService({required this.user, required this.calls});

  @override
  Future<UserModel?> getCurrentUser({bool isAppStartup = false}) async => user;

  @override
  Future<void> updateCommissionRate(double rate) async {
    calls.add('user:$rate');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSeasonService implements ISeasonService {
  final String userId;
  final List<String> calls;

  _FakeSeasonService({required this.userId, required this.calls});

  @override
  Future<SeasonModel> createSeason(
    String userId,
    String name,
    double commissionRate,
  ) async {
    return SeasonModel(
      id: 'season-1',
      userId: userId,
      name: name,
      startDate: DateTime(2026),
      commissionRate: commissionRate,
    );
  }

  @override
  Future<void> updateSeasonCommissionRate(
    String seasonId,
    double commissionRate,
  ) async {
    calls.add('season:$commissionRate');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
