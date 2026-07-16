import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../contracts/season_service_contract.dart';
import '../supabase_mapper.dart';

/// Supabase ile çalışan sezon servisi
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
    final response =
        await _client
            .from('seasons')
            .select()
            .eq('user_id', userId)
            .eq('is_active', true)
            .maybeSingle();

    if (response == null) return null;
    return seasonFromDbMap(response);
  }

  @override
  Future<SeasonModel> createSeason(
    String userId,
    String name,
    double commissionRate,
  ) async {
    await _client
        .from('seasons')
        .update({'is_active': false})
        .eq('user_id', userId)
        .eq('is_active', true);

    final season = SeasonModel(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      startDate: DateTime.now(),
      commissionRate: commissionRate,
    );

    final response =
        await _client
            .from('seasons')
            .insert(seasonToDbMap(season))
            .select()
            .single();

    return seasonFromDbMap(response);
  }

  @override
  Future<void> setActiveSeason(String userId, String seasonId) async {
    await _client
        .from('seasons')
        .update({'is_active': false})
        .eq('user_id', userId)
        .eq('is_active', true);

    await _client
        .from('seasons')
        .update({'is_active': true})
        .eq('id', seasonId)
        .eq('user_id', userId)
        .isFilter('end_date', null);
  }

  @override
  Future<void> updateSeason(SeasonModel season) async {
    await _client
        .from('seasons')
        .update(seasonToDbMap(season))
        .eq('id', season.id);
  }

  @override
  Future<void> updateSeasonCommissionRate(
    String seasonId,
    double commissionRate,
  ) async {
    await _client
        .from('seasons')
        .update({'commission_rate': commissionRate})
        .eq('id', seasonId);
  }

  @override
  Future<void> endSeason(String seasonId) async {
    await _client
        .from('seasons')
        .update({
          'is_active': false,
          'end_date': DateTime.now().toIso8601String(),
        })
        .eq('id', seasonId);
  }

  @override
  Future<void> updateSeasonTotals(
    String seasonId,
    double grossEarning,
    double commission,
    double netEarning,
    double kg,
  ) async {
    final response =
        await _client.from('seasons').select().eq('id', seasonId).single();

    final season = seasonFromDbMap(response);

    await _client
        .from('seasons')
        .update({
          'total_gross_earning': season.totalGrossEarning + grossEarning,
          'total_commission': season.totalCommission + commission,
          'total_net_earning': season.totalNetEarning + netEarning,
          'total_harvests': season.totalHarvests + 1,
          'total_kg': season.totalKg + kg,
        })
        .eq('id', seasonId);
  }

  @override
  Future<void> recalculateSeasonTotals(String seasonId) async {
    final harvestsResponse = await _client
        .from('harvests')
        .select()
        .eq('season_id', seasonId);

    final seasonHarvests =
        (harvestsResponse as List<dynamic>)
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

    await _client
        .from('seasons')
        .update({
          'total_gross_earning': totalGross,
          'total_commission': totalCommission,
          'total_net_earning': totalNet,
          'total_harvests': seasonHarvests.length,
          'total_kg': totalKg,
        })
        .eq('id', seasonId);
  }
}
