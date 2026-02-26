import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'supabase_mapper.dart';

/// Sezon servisi interface'i
/// Firebase entegrasyonu için hazır altyapı
abstract class ISeasonService {
  Future<List<SeasonModel>> getSeasonsByUserId(String userId);
  Future<SeasonModel?> getActiveSeasonByUserId(String userId);
  Future<SeasonModel> createSeason(String userId, String name);
  Future<void> updateSeason(SeasonModel season);
  Future<void> endSeason(String seasonId);
  Future<void> updateSeasonTotals(String seasonId, double grossEarning,
      double commission, double netEarning, double kg);
  Future<void> recalculateSeasonTotals(String seasonId);
}

/// Local Storage ile çalışan Season servisi
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
  Future<SeasonModel> createSeason(String userId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final seasonsJson = prefs.getString(_seasonsKey);

    List<dynamic> seasons = [];
    if (seasonsJson != null) {
      seasons = jsonDecode(seasonsJson);

      // Mevcut aktif sezonları kapat
      for (int i = 0; i < seasons.length; i++) {
        final season = seasons[i] as Map<String, dynamic>;
        if (season['userId'] == userId && season['isActive'] == true) {
          season['isActive'] = false;
          season['endDate'] = DateTime.now().toIso8601String();
        }
      }
    }

    final newSeason = SeasonModel(
      id: _uuid.v4(),
      userId: userId,
      name: name,
      startDate: DateTime.now(),
    );

    seasons.add(newSeason.toJson());
    await prefs.setString(_seasonsKey, jsonEncode(seasons));

    return newSeason;
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
  Future<void> updateSeasonTotals(String seasonId, double grossEarning,
      double commission, double netEarning, double kg) async {
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

    final seasonHarvests = allHarvests
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

/// Supabase ile çalışan Season servisi
class SupabaseSeasonService implements ISeasonService {
  final SupabaseClient _client;

  SupabaseSeasonService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<SeasonModel>> getSeasonsByUserId(String userId) async {
    final response = await _client
        .from('seasons')
        .select()
        .eq('user_id', userId)
        .order('start_date', ascending: false);

    return (response as List<dynamic>)
        .map((item) => seasonFromDbMap(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SeasonModel?> getActiveSeasonByUserId(String userId) async {
    final response = await _client
        .from('seasons')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return seasonFromDbMap(response);
  }

  @override
  Future<SeasonModel> createSeason(String userId, String name) async {
    await _client
        .from('seasons')
        .update({
          'is_active': false,
          'end_date': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('is_active', true);

    final season = SeasonModel(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      startDate: DateTime.now(),
    );

    final response = await _client
        .from('seasons')
        .insert(seasonToDbMap(season))
        .select()
        .single();

    return seasonFromDbMap(response);
  }

  @override
  Future<void> updateSeason(SeasonModel season) async {
    await _client
        .from('seasons')
        .update(seasonToDbMap(season))
        .eq('id', season.id);
  }

  @override
  Future<void> endSeason(String seasonId) async {
    await _client.from('seasons').update({
      'is_active': false,
      'end_date': DateTime.now().toIso8601String(),
    }).eq('id', seasonId);
  }

  @override
  Future<void> updateSeasonTotals(
    String seasonId,
    double grossEarning,
    double commission,
    double netEarning,
    double kg,
  ) async {
    final response = await _client
        .from('seasons')
        .select()
        .eq('id', seasonId)
        .single();

    final season = seasonFromDbMap(response);

    await _client.from('seasons').update({
      'total_gross_earning': season.totalGrossEarning + grossEarning,
      'total_commission': season.totalCommission + commission,
      'total_net_earning': season.totalNetEarning + netEarning,
      'total_harvests': season.totalHarvests + 1,
      'total_kg': season.totalKg + kg,
    }).eq('id', seasonId);
  }

  @override
  Future<void> recalculateSeasonTotals(String seasonId) async {
    final harvestsResponse = await _client
        .from('harvests')
        .select()
        .eq('season_id', seasonId);

    final seasonHarvests = (harvestsResponse as List<dynamic>)
        .map((item) => harvestFromDbMap(item as Map<String, dynamic>))
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

    await _client.from('seasons').update({
      'total_gross_earning': totalGross,
      'total_commission': totalCommission,
      'total_net_earning': totalNet,
      'total_harvests': seasonHarvests.length,
      'total_kg': totalKg,
    }).eq('id', seasonId);
  }
}
