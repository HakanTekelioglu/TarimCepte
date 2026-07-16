import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/contracts/harvest_service_contract.dart';
import '../services/contracts/season_service_contract.dart';

/// Hasat state yönetimi
class HarvestProvider extends ChangeNotifier {
  final IHarvestService _harvestService;
  final ISeasonService _seasonService;
  List<HarvestModel> _harvests = [];
  bool _isLoading = false;
  String? _error;

  HarvestProvider({
    required IHarvestService harvestService,
    required ISeasonService seasonService,
  }) : _harvestService = harvestService,
       _seasonService = seasonService;

  List<HarvestModel> get harvests => _harvests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Toplam brüt kazanç
  double get totalGrossEarning =>
      _harvests.fold(0, (sum, h) => sum + h.grossEarning);

  /// Toplam komisyon
  double get totalCommission =>
      _harvests.fold(0, (sum, h) => sum + h.commissionAmount);

  /// Toplam net kazanç
  double get totalNetEarning =>
      _harvests.fold(0, (sum, h) => sum + h.netEarning);

  /// Toplam kg
  double get totalKg => _harvests.fold(0, (sum, h) => sum + h.totalKg);

  /// Toplam sandık
  int get totalCrates => _harvests.fold(0, (sum, h) => sum + h.crateCount);

  /// Kullanıcının hasatlarını yükle
  Future<void> loadHarvestsByUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _harvests = await _harvestService.getHarvestsByUserId(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sezonun hasatlarını yükle
  Future<void> loadHarvestsBySeason(String seasonId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _harvests = await _harvestService.getHarvestsBySeasonId(seasonId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Yeni hasat ekle
  Future<void> addHarvest({
    required String userId,
    required String productId,
    required String productName,
    required int crateCount,
    required double totalKg,
    required double pricePerKg,
    required double commissionRate,
    required String seasonId,
    String? notes,
  }) async {
    try {
      final harvest = HarvestModel(
        id: '',
        userId: userId,
        productId: productId,
        productName: productName,
        crateCount: crateCount,
        totalKg: totalKg,
        pricePerKg: pricePerKg,
        commissionRate: commissionRate,
        seasonId: seasonId,
        harvestDate: DateTime.now(),
        notes: notes,
      );

      final newHarvest = await _harvestService.addHarvest(harvest);
      _harvests.insert(0, newHarvest);

      // Sezon toplamlarını güncelle
      await _seasonService.updateSeasonTotals(
        seasonId,
        newHarvest.grossEarning,
        newHarvest.commissionAmount,
        newHarvest.netEarning,
        newHarvest.totalKg,
      );

      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Hasat sil
  Future<void> deleteHarvest(String id) async {
    try {
      final deletedHarvest = await _harvestService.deleteHarvest(id);
      _harvests.removeWhere((h) => h.id == id);

      if (deletedHarvest != null) {
        await _seasonService.recalculateSeasonTotals(deletedHarvest.seasonId);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Ürüne göre hasatları filtrele
  List<HarvestModel> getHarvestsByProduct(String productId) {
    return _harvests.where((h) => h.productId == productId).toList();
  }

  /// Tarihe göre hasatları filtrele
  List<HarvestModel> getHarvestsByDateRange(DateTime start, DateTime end) {
    return _harvests
        .where(
          (h) => h.harvestDate.isAfter(start) && h.harvestDate.isBefore(end),
        )
        .toList();
  }

  /// Kullanıcı/sezon değişiminde eski veriyi temizle
  void clearHarvests() {
    _harvests = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
