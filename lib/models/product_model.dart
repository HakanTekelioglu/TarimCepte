/// Ürün modeli - Hal'deki ürünler ve fiyatları
class ProductModel {
  final String id;
  final String name;
  final double pricePerKg; // Kilogram başına fiyat (TL)
  final String category; // Ürün kategorisi (meyve, sebze)
  final DateTime updatedAt;
  final bool isActive;

  ProductModel({
    required this.id,
    required this.name,
    required this.pricePerKg,
    this.category = 'sebze',
    required this.updatedAt,
    this.isActive = true,
  });

  /// JSON'dan model oluştur
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      pricePerKg: ((json['price_per_kg'] ?? json['pricePerKg']) as num).toDouble(),
      category: json['category'] as String? ?? 'sebze',
      updatedAt: DateTime.parse((json['updated_at'] ?? json['updatedAt']) as String),
      isActive: (json['is_active'] ?? json['isActive']) as bool? ?? true,
    );
  }

  /// Modeli JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pricePerKg': pricePerKg,
      'category': category,
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Güncellenmiş kopya oluştur
  ProductModel copyWith({
    String? id,
    String? name,
    double? pricePerKg,
    String? category,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      category: category ?? this.category,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
