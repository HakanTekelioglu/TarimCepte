class ProductPriceModel {
  final String id;
  final String productId;
  final String city;
  final String? district;
  final double pricePerKg;
  final DateTime updatedAt;

  ProductPriceModel({
    required this.id,
    required this.productId,
    required this.city,
    this.district,
    required this.pricePerKg,
    required this.updatedAt,
  });

  factory ProductPriceModel.fromJson(Map<String, dynamic> json) {
    return ProductPriceModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      city: json['city'] as String,
      district: json['district'] as String?,
      pricePerKg: (json['price_per_kg'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'city': city,
      if (district != null) 'district': district,
      'price_per_kg': pricePerKg,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
