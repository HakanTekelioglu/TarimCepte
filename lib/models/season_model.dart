/// Sezon modeli - Tarım sezonu bilgisi
class SeasonModel {
  final String id;
  final String userId;
  final String name; // Sezon adı (örn: "2024 İlkbahar")
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final double totalGrossEarning;
  final double totalCommission;
  final double totalNetEarning;
  final int totalHarvests;
  final double totalKg;

  SeasonModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.totalGrossEarning = 0,
    this.totalCommission = 0,
    this.totalNetEarning = 0,
    this.totalHarvests = 0,
    this.totalKg = 0,
  });

  /// JSON'dan model oluştur
  factory SeasonModel.fromJson(Map<String, dynamic> json) {
    return SeasonModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      totalGrossEarning: (json['totalGrossEarning'] as num?)?.toDouble() ?? 0,
      totalCommission: (json['totalCommission'] as num?)?.toDouble() ?? 0,
      totalNetEarning: (json['totalNetEarning'] as num?)?.toDouble() ?? 0,
      totalHarvests: json['totalHarvests'] as int? ?? 0,
      totalKg: (json['totalKg'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Modeli JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'totalGrossEarning': totalGrossEarning,
      'totalCommission': totalCommission,
      'totalNetEarning': totalNetEarning,
      'totalHarvests': totalHarvests,
      'totalKg': totalKg,
    };
  }

  /// Güncellenmiş kopya oluştur
  SeasonModel copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    double? totalGrossEarning,
    double? totalCommission,
    double? totalNetEarning,
    int? totalHarvests,
    double? totalKg,
  }) {
    return SeasonModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      totalGrossEarning: totalGrossEarning ?? this.totalGrossEarning,
      totalCommission: totalCommission ?? this.totalCommission,
      totalNetEarning: totalNetEarning ?? this.totalNetEarning,
      totalHarvests: totalHarvests ?? this.totalHarvests,
      totalKg: totalKg ?? this.totalKg,
    );
  }
}
