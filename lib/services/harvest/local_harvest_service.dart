import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../contracts/harvest_service_contract.dart';

/// Local Storage ile çalışan hasat servisi
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
