import '../../models/harvest_model.dart';

abstract interface class IHarvestService {
  Future<List<HarvestModel>> getHarvestsByUserId(String userId);
  Future<List<HarvestModel>> getHarvestsBySeasonId(String seasonId);
  Future<HarvestModel> addHarvest(HarvestModel harvest);
  Future<void> updateHarvest(HarvestModel harvest);
  Future<HarvestModel?> deleteHarvest(String id);
}
