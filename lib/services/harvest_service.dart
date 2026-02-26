import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'supabase_mapper.dart';

/// Hasat servisi interface'i
/// Firebase entegrasyonu için hazır altyapı
abstract class IHarvestService {
  Future<List<HarvestModel>> getHarvestsByUserId(String userId);
  Future<List<HarvestModel>> getHarvestsBySeasonId(String seasonId);
  Future<HarvestModel> addHarvest(HarvestModel harvest);
  Future<void> updateHarvest(HarvestModel harvest);
  Future<HarvestModel?> deleteHarvest(String id);
}

/// Local Storage ile çalışan Harvest servisi
class LocalHarvestService implements IHarvestService {
  static const String _harvestsKey = 'harvests';
  final Uuid _uuid = const Uuid();

  @override
  Future<List<HarvestModel>> getHarvestsByUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final harvestsJson = prefs.getString(_harvestsKey);

    if (harvestsJson == null) return [];

    final List<dynamic> harvests = jsonDecode(harvestsJson);
    return harvests
        .map((h) => HarvestModel.fromJson(h as Map<String, dynamic>))
        .where((h) => h.userId == userId)
        .toList()
      ..sort((a, b) => b.harvestDate.compareTo(a.harvestDate));
  }

  @override
  Future<List<HarvestModel>> getHarvestsBySeasonId(String seasonId) async {
    final prefs = await SharedPreferences.getInstance();
    final harvestsJson = prefs.getString(_harvestsKey);

    if (harvestsJson == null) return [];

    final List<dynamic> harvests = jsonDecode(harvestsJson);
    return harvests
        .map((h) => HarvestModel.fromJson(h as Map<String, dynamic>))
        .where((h) => h.seasonId == seasonId)
        .toList()
      ..sort((a, b) => b.harvestDate.compareTo(a.harvestDate));
  }

  @override
  Future<HarvestModel> addHarvest(HarvestModel harvest) async {
    final prefs = await SharedPreferences.getInstance();
    final harvestsJson = prefs.getString(_harvestsKey);

    List<dynamic> harvests = [];
    if (harvestsJson != null) {
      harvests = jsonDecode(harvestsJson);
    }

    final newHarvest = HarvestModel(
      id: _uuid.v4(),
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

    harvests.add(newHarvest.toJson());
    await prefs.setString(_harvestsKey, jsonEncode(harvests));

    return newHarvest;
  }

  @override
  Future<void> updateHarvest(HarvestModel harvest) async {
    final prefs = await SharedPreferences.getInstance();
    final harvestsJson = prefs.getString(_harvestsKey);

    if (harvestsJson == null) return;

    final List<dynamic> harvests = jsonDecode(harvestsJson);
    for (int i = 0; i < harvests.length; i++) {
      if ((harvests[i] as Map<String, dynamic>)['id'] == harvest.id) {
        harvests[i] = harvest.toJson();
        break;
      }
    }

    await prefs.setString(_harvestsKey, jsonEncode(harvests));
  }

  @override
  Future<HarvestModel?> deleteHarvest(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final harvestsJson = prefs.getString(_harvestsKey);

    if (harvestsJson == null) return null;

    final List<dynamic> harvests = jsonDecode(harvestsJson);
    HarvestModel? deletedHarvest;

    for (final item in harvests) {
      final harvestMap = item as Map<String, dynamic>;
      if (harvestMap['id'] == id) {
        deletedHarvest = HarvestModel.fromJson(harvestMap);
        break;
      }
    }

    harvests.removeWhere((h) => (h as Map<String, dynamic>)['id'] == id);

    await prefs.setString(_harvestsKey, jsonEncode(harvests));
    return deletedHarvest;
  }
}

/// Supabase ile çalışan Harvest servisi
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

    final response = await _client
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
    final response = await _client
        .from('harvests')
        .delete()
        .eq('id', id)
        .select()
        .maybeSingle();

    if (response == null) return null;
    return harvestFromDbMap(response as Map<String, dynamic>);
  }
}
