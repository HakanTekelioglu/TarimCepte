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
      _activeSeason = await _seasonService.getActiveSeasonByUserId(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Yeni sezon oluştur
  Future<void> createSeason(String userId, String name) async {
    try {
      final season = await _seasonService.createSeason(userId, name);
      
      // Eski aktif sezonu güncelle
      if (_activeSeason != null) {
        final index = _seasons.indexWhere((s) => s.id == _activeSeason!.id);
        if (index != -1) {
          _seasons[index] = _seasons[index].copyWith(
            isActive: false,
            endDate: DateTime.now(),
          );
        }
      }

      _seasons.insert(0, season);
      _activeSeason = season;
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
