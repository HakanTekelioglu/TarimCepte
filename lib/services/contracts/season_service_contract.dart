import '../../models/season_model.dart';

abstract interface class ISeasonService {
  Future<List<SeasonModel>> getSeasonsByUserId(String userId);
  Future<SeasonModel?> getActiveSeasonByUserId(String userId);
  Future<SeasonModel> createSeason(
    String userId,
    String name,
    double commissionRate,
  );
  Future<void> setActiveSeason(String userId, String seasonId);
  Future<void> updateSeasonCommissionRate(
    String seasonId,
    double commissionRate,
  );
  Future<void> updateSeason(SeasonModel season);
  Future<void> endSeason(String seasonId);
  Future<void> updateSeasonTotals(
    String seasonId,
    double grossEarning,
    double commission,
    double netEarning,
    double kg,
  );
  Future<void> recalculateSeasonTotals(String seasonId);
}
