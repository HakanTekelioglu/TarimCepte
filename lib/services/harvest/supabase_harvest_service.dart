import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../contracts/harvest_service_contract.dart';
import '../supabase_mapper.dart';

/// Supabase ile çalışan hasat servisi
class SupabaseHarvestService implements IHarvestService {
  final SupabaseClient _client;

  SupabaseHarvestService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<List<HarvestModel>> getHarvestsByUserId(String userId) async {
    final response = await _client
        .from('harvests')
        .select()
        .eq('user_id', userId)
        .order('harvest_date', ascending: false);

    return (response as List<dynamic>)
        .map((item) => harvestFromDbMap(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<HarvestModel>> getHarvestsBySeasonId(String seasonId) async {
    final response = await _client
        .from('harvests')
        .select()
        .eq('season_id', seasonId)
        .order('harvest_date', ascending: false);

    return (response as List<dynamic>)
        .map((item) => harvestFromDbMap(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<HarvestModel> addHarvest(HarvestModel harvest) async {
    final newHarvest = HarvestModel(
      id: const Uuid().v4(),
      userId: harvest.userId,
      productId: harvest.productId,
      productName: harvest.productName,
      crateCount: harvest.crateCount,
      totalKg: harvest.totalKg,
      pricePerKg: harvest.pricePerKg,
      commissionRate: harvest.commissionRate,
      seasonId: harvest.seasonId,
      harvestDate: harvest.harvestDate,
      notes: harvest.notes,
    );

    final response =
        await _client
            .from('harvests')
            .insert(harvestToDbMap(newHarvest))
            .select()
            .single();

    return harvestFromDbMap(response);
  }

  @override
  Future<void> updateHarvest(HarvestModel harvest) async {
    await _client
        .from('harvests')
        .update(harvestToDbMap(harvest))
        .eq('id', harvest.id);
  }

  @override
  Future<HarvestModel?> deleteHarvest(String id) async {
    final response =
        await _client
            .from('harvests')
            .delete()
            .eq('id', id)
            .select()
            .maybeSingle();

    if (response == null) return null;
    return harvestFromDbMap(response);
  }
}
