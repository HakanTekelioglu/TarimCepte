/// Hasat kaydı modeli - Seradan toplanan ürün bilgisi
class HarvestModel {
  final String id;
  final String userId;
  final String productId;
  final String productName; // Kolay erişim için
  final int crateCount; // Sandık sayısı
  final double totalKg; // Toplam kilogram
  final double pricePerKg; // O anki kg fiyatı
  final double grossEarning; // Brüt kazanç
  final double commissionRate; // Komisyon oranı (%)
  final double commissionAmount; // Komisyon tutarı
  final double netEarning; // Net kazanç
  final String seasonId; // Hangi sezon
  final DateTime harvestDate;
  final String? notes; // Ek notlar

  HarvestModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.crateCount,
    required this.totalKg,
    required this.pricePerKg,
    required this.commissionRate,
    required this.seasonId,
    required this.harvestDate,
    this.notes,
  })  : grossEarning = totalKg * pricePerKg,
        commissionAmount = (totalKg * pricePerKg) * (commissionRate / 100),
        netEarning = (totalKg * pricePerKg) -
            ((totalKg * pricePerKg) * (commissionRate / 100));

  /// JSON'dan model oluştur
  factory HarvestModel.fromJson(Map<String, dynamic> json) {
    return HarvestModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      crateCount: json['crateCount'] as int,
      totalKg: (json['totalKg'] as num).toDouble(),
      pricePerKg: (json['pricePerKg'] as num).toDouble(),
      commissionRate: (json['commissionRate'] as num).toDouble(),
      seasonId: json['seasonId'] as String,
      harvestDate: DateTime.parse(json['harvestDate'] as String),
      notes: json['notes'] as String?,
    );
  }

  /// Modeli JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'crateCount': crateCount,
      'totalKg': totalKg,
      'pricePerKg': pricePerKg,
      'grossEarning': grossEarning,
      'commissionRate': commissionRate,
      'commissionAmount': commissionAmount,
      'netEarning': netEarning,
      'seasonId': seasonId,
      'harvestDate': harvestDate.toIso8601String(),
      'notes': notes,
    };
  }

  /// Güncellenmiş kopya oluştur
  HarvestModel copyWith({
    String? id,
    String? userId,
    String? productId,
    String? productName,
    int? crateCount,
    double? totalKg,
    double? pricePerKg,
    double? commissionRate,
    String? seasonId,
    DateTime? harvestDate,
    String? notes,
  }) {
    return HarvestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      crateCount: crateCount ?? this.crateCount,
      totalKg: totalKg ?? this.totalKg,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      commissionRate: commissionRate ?? this.commissionRate,
      seasonId: seasonId ?? this.seasonId,
      harvestDate: harvestDate ?? this.harvestDate,
      notes: notes ?? this.notes,
    );
  }
}
