import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../contracts/season_service_contract.dart';

/// Local Storage ile çalışan sezon servisi
class LocalSeasonService implements ISeasonService {
  static const String _seasonsKey = 'seasons';
  static const String _harvestsKey = 'harvests';
  final Uuid _uuid = const Uuid();

  @override
  Future<List<SeasonModel>> getSeasonsByUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final seasonsJson = prefs.getString(_seasonsKey);

    if (seasonsJson == null) return [];

    final List<dynamic> seasons = jsonDecode(seasonsJson);
    return seasons
        .map((s) => SeasonModel.fromJson(s as Map<String, dynamic>))
        .where((s) => s.userId == userId)
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  @override
  Future<SeasonModel?> getActiveSeasonByUserId(String userId) async {
    final seasons = await getSeasonsByUserId(userId);
    try {
      return seasons.firstWhere((s) => s.isActive);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<SeasonModel> createSeason(
    String userId,
    String name,
    double commissionRate,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final seasonsJson = prefs.getString(_seasonsKey);

    List<dynamic> seasons = [];
    if (seasonsJson != null) {
      seasons = jsonDecode(seasonsJson);

      // Mevcut aktif sezonları sadece pasifleştir (sonlandırma yok)
      for (int i = 0; i < seasons.length; i++) {
        final season = seasons[i] as Map<String, dynamic>;
        if (season['userId'] == userId && season['isActive'] == true) {
          season['isActive'] = false;
        }
      }
    }

    final newSeason = SeasonModel(
      id: _uuid.v4(),
      userId: userId,
      name: name,
      startDate: DateTime.now(),
      commissionRate: commissionRate,
    );

    seasons.add(newSeason.toJson());
    await prefs.setString(_seasonsKey, jsonEncode(seasons));

    return newSeason;
  }

  @override
  Future<void> setActiveSeason(String userId, String seasonId) async {
    final prefs = await SharedPreferences.getInstance();
    final seasonsJson = prefs.getString(_seasonsKey);

    if (seasonsJson == null) return;

    final List<dynamic> seasons = jsonDecode(seasonsJson);
    for (int i = 0; i < seasons.length; i++) {
      final season = seasons[i] as Map<String, dynamic>;
      if (season['userId'] != userId || season['endDate'] != null) continue;
      season['isActive'] = season['id'] == seasonId;
    }

    await prefs.setString(_seasonsKey, jsonEncode(seasons));
  }

  @override
  Future<void> updateSeasonCommissionRate(
    String seasonId,
    double commissionRate,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final seasonsJson = prefs.getString(_seasonsKey);

    if (seasonsJson == null) return;

    final List<dynamic> seasons = jsonDecode(seasonsJson);
    for (int i = 0; i < seasons.length; i++) {
      final season = seasons[i] as Map<String, dynamic>;
      if (season['id'] == seasonId) {
        season['commissionRate'] = commissionRate;
        break;
      }
    }

    await prefs.setString(_seasonsKey, jsonEncode(seasons));
  }

  @override
  Future<void> updateSeason(SeasonModel season) async {
    final prefs = await SharedPreferences.getInstance();
    final seasonsJson = prefs.getString(_seasonsKey);

    if (seasonsJson == null) return;

    final List<dynamic> seasons = jsonDecode(seasonsJson);
    for (int i = 0; i < seasons.length; i++) {
      if ((seasons[i] as Map<String, dynamic>)['id'] == season.id) {
        seasons[i] = season.toJson();
        break;
      }
    }

    await prefs.setString(_seasonsKey, jsonEncode(seasons));
  }

  @override
  Future<void> endSeason(String seasonId) async {
    final prefs = await SharedPreferences.getInstance();
    final seasonsJson = prefs.getString(_seasonsKey);

    if (seasonsJson == null) return;

    final List<dynamic> seasons = jsonDecode(seasonsJson);
    for (int i = 0; i < seasons.length; i++) {
      if ((seasons[i] as Map<String, dynamic>)['id'] == seasonId) {
        seasons[i]['isActive'] = false;
        seasons[i]['endDate'] = DateTime.now().toIso8601String();
        break;
      }
    }

    await prefs.setString(_seasonsKey, jsonEncode(seasons));
  }

  @override
  Future<void> updateSeasonTotals(
    String seasonId,
    double grossEarning,
    double commission,
    double netEarning,
    double kg,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final seasonsJson = prefs.getString(_seasonsKey);

    if (seasonsJson == null) return;

    final List<dynamic> seasons = jsonDecode(seasonsJson);
    for (int i = 0; i < seasons.length; i++) {
      final season = seasons[i] as Map<String, dynamic>;
      if (season['id'] == seasonId) {
        season['totalGrossEarning'] =
            (season['totalGrossEarning'] ?? 0) + grossEarning;
        season['totalCommission'] =
            (season['totalCommission'] ?? 0) + commission;
        season['totalNetEarning'] =
            (season['totalNetEarning'] ?? 0) + netEarning;
        season['totalHarvests'] = (season['totalHarvests'] ?? 0) + 1;
        season['totalKg'] = (season['totalKg'] ?? 0) + kg;
        break;
      }
    }

    await prefs.setString(_seasonsKey, jsonEncode(seasons));
  }

  @override
  Future<void> recalculateSeasonTotals(String seasonId) async {
    final prefs = await SharedPreferences.getInstance();
    final seasonsJson = prefs.getString(_seasonsKey);

    if (seasonsJson == null) return;

    final harvestsJson = prefs.getString(_harvestsKey);
    final List<dynamic> allHarvests =
        harvestsJson == null ? [] : jsonDecode(harvestsJson);

    final seasonHarvests =
        allHarvests
            .map((h) => HarvestModel.fromJson(h as Map<String, dynamic>))
            .where((h) => h.seasonId == seasonId)
            .toList();

    final totalGross = seasonHarvests.fold<double>(
      0,
      (sum, harvest) => sum + harvest.grossEarning,
    );
    final totalCommission = seasonHarvests.fold<double>(
      0,
      (sum, harvest) => sum + harvest.commissionAmount,
    );
    final totalNet = seasonHarvests.fold<double>(
      0,
      (sum, harvest) => sum + harvest.netEarning,
    );
    final totalKg = seasonHarvests.fold<double>(
      0,
      (sum, harvest) => sum + harvest.totalKg,
    );

    final List<dynamic> seasons = jsonDecode(seasonsJson);
    for (int i = 0; i < seasons.length; i++) {
      final season = seasons[i] as Map<String, dynamic>;
      if (season['id'] == seasonId) {
        season['totalGrossEarning'] = totalGross;
        season['totalCommission'] = totalCommission;
        season['totalNetEarning'] = totalNet;
        season['totalHarvests'] = seasonHarvests.length;
        season['totalKg'] = totalKg;
        break;
      }
    }

    await prefs.setString(_seasonsKey, jsonEncode(seasons));
  }
}
