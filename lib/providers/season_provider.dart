import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Sezon state yönetimi
class SeasonProvider extends ChangeNotifier {
  final ISeasonService _seasonService;
  List<SeasonModel> _seasons = [];
  SeasonModel? _activeSeason;
  bool _isLoading = false;
  String? _error;

  SeasonProvider({ISeasonService? seasonService})
      : _seasonService = seasonService ?? LocalSeasonService();

  List<SeasonModel> get seasons => _seasons;
  SeasonModel? get activeSeason => _activeSeason;
  bool get isLoading => _isLoading;
  bool get hasActiveSeason => _activeSeason != null;
  String? get error => _error;

  /// Kullanıcının sezonlarını yükle
  Future<void> loadSeasons(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _seasons = await _seasonService.getSeasonsByUserId(userId);

      // Geçmişte oluşmuş tutarsızlıkları düzeltmek için
      // sezon toplamlarını mevcut hasat kayıtlarından yeniden hesapla.
      if (_seasons.isNotEmpty) {
        for (final season in _seasons) {
          await _seasonService.recalculateSeasonTotals(season.id);
        }
        _seasons = await _seasonService.getSeasonsByUserId(userId);
      }

      _activeSeason = await _seasonService.getActiveSeasonByUserId(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Yeni sezon oluştur
  Future<void> createSeason(
    String userId,
    String name,
    double commissionRate,
  ) async {
    try {
      final season = await _seasonService.createSeason(
        userId,
        name,
        commissionRate,
      );

      // Eski aktif sezonu sadece pasifleştir (sonlandırma yok)
      for (int i = 0; i < _seasons.length; i++) {
        if (_seasons[i].isActive) {
          _seasons[i] = _seasons[i].copyWith(isActive: false);
        }
      }

      _seasons.insert(0, season);
      _activeSeason = season;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Sezonlar arasında geçiş yap
  Future<void> setActiveSeason(String userId, String seasonId) async {
    try {
      await _seasonService.setActiveSeason(userId, seasonId);

      for (int i = 0; i < _seasons.length; i++) {
        final isSelected = _seasons[i].id == seasonId;
        _seasons[i] = _seasons[i].copyWith(isActive: isSelected);
        if (isSelected) {
          _activeSeason = _seasons[i];
        }
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Sezonu sonlandır
  Future<void> endSeason(String seasonId) async {
    try {
      await _seasonService.endSeason(seasonId);
      
      final index = _seasons.indexWhere((s) => s.id == seasonId);
      if (index != -1) {
        _seasons[index] = _seasons[index].copyWith(
          isActive: false,
          endDate: DateTime.now(),
        );
      }

      if (_activeSeason?.id == seasonId) {
        _activeSeason = null;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Aktif sezonu yenile (güncel toplamlar için)
  Future<void> refreshActiveSeason(String userId) async {
    _activeSeason = await _seasonService.getActiveSeasonByUserId(userId);
    
    if (_activeSeason != null) {
      final index = _seasons.indexWhere((s) => s.id == _activeSeason!.id);
      if (index != -1) {
        _seasons[index] = _activeSeason!;
      }
    }
    
    notifyListeners();
  }

  /// Sezon detayını getir
  SeasonModel? getSeasonById(String id) {
    try {
      return _seasons.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}
