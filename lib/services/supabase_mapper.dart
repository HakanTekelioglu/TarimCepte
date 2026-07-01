import '../models/models.dart';

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  return DateTime.parse(value as String);
}

Map<String, dynamic> userToDbMap(UserModel user) {
  return {
    'id': user.id,
    'phone_number': user.phoneNumber,
    'email': user.email,
    'full_name': user.fullName,
    'commission_rate': user.commissionRate,
    'created_at': user.createdAt.toIso8601String(),
    'is_admin': user.isAdmin,
    'city': user.city,
    'district': user.district,
  };
}

UserModel userFromDbMap(Map<String, dynamic> map) {
  return UserModel(
    id: map['id'] as String,
    phoneNumber: map['phone_number'] as String? ?? '',
    email: map['email'] as String?,
    fullName: map['full_name'] as String,
    commissionRate: (map['commission_rate'] as num?)?.toDouble() ?? 8.0,
    createdAt: _parseDate(map['created_at']),
    isAdmin: map['is_admin'] as bool? ?? false,
    city: map['city'] as String?,
    district: map['district'] as String?,
  );
}

Map<String, dynamic> productToDbMap(ProductModel product) {
  return {
    'id': product.id,
    'name': product.name,
    'price_per_kg': product.pricePerKg,
    'category': product.category,
    'updated_at': product.updatedAt.toIso8601String(),
    'is_active': product.isActive,
  };
}

ProductModel productFromDbMap(Map<String, dynamic> map) {
  return ProductModel(
    id: map['id'] as String,
    name: map['name'] as String,
    pricePerKg: (map['price_per_kg'] as num).toDouble(),
    category: map['category'] as String? ?? 'sebze',
    updatedAt: _parseDate(map['updated_at']),
    isActive: map['is_active'] as bool? ?? true,
  );
}

Map<String, dynamic> seasonToDbMap(SeasonModel season) {
  return {
    'id': season.id,
    'user_id': season.userId,
    'name': season.name,
    'start_date': season.startDate.toIso8601String(),
    'end_date': season.endDate?.toIso8601String(),
    'is_active': season.isActive,
    'commission_rate': season.commissionRate,
    'total_gross_earning': season.totalGrossEarning,
    'total_commission': season.totalCommission,
    'total_net_earning': season.totalNetEarning,
    'total_harvests': season.totalHarvests,
    'total_kg': season.totalKg,
  };
}

SeasonModel seasonFromDbMap(Map<String, dynamic> map) {
  return SeasonModel(
    id: map['id'] as String,
    userId: map['user_id'] as String,
    name: map['name'] as String,
    startDate: _parseDate(map['start_date']),
    endDate: map['end_date'] != null ? _parseDate(map['end_date']) : null,
    isActive: map['is_active'] as bool? ?? true,
    commissionRate: (map['commission_rate'] as num?)?.toDouble() ?? 8.0,
    totalGrossEarning: (map['total_gross_earning'] as num?)?.toDouble() ?? 0,
    totalCommission: (map['total_commission'] as num?)?.toDouble() ?? 0,
    totalNetEarning: (map['total_net_earning'] as num?)?.toDouble() ?? 0,
    totalHarvests: map['total_harvests'] as int? ?? 0,
    totalKg: (map['total_kg'] as num?)?.toDouble() ?? 0,
  );
}

Map<String, dynamic> harvestToDbMap(HarvestModel harvest) {
  return {
    'id': harvest.id,
    'user_id': harvest.userId,
    'product_id': harvest.productId,
    'product_name': harvest.productName,
    'crate_count': harvest.crateCount,
    'total_kg': harvest.totalKg,
    'price_per_kg': harvest.pricePerKg,
    'gross_earning': harvest.grossEarning,
    'commission_rate': harvest.commissionRate,
    'commission_amount': harvest.commissionAmount,
    'net_earning': harvest.netEarning,
    'season_id': harvest.seasonId,
    'harvest_date': harvest.harvestDate.toIso8601String(),
    'notes': harvest.notes,
  };
}

HarvestModel harvestFromDbMap(Map<String, dynamic> map) {
  return HarvestModel(
    id: map['id'] as String,
    userId: map['user_id'] as String,
    productId: map['product_id'] as String,
    productName: map['product_name'] as String,
    crateCount: map['crate_count'] as int,
    totalKg: (map['total_kg'] as num).toDouble(),
    pricePerKg: (map['price_per_kg'] as num).toDouble(),
    commissionRate: (map['commission_rate'] as num).toDouble(),
    seasonId: map['season_id'] as String,
    harvestDate: _parseDate(map['harvest_date']),
    notes: map['notes'] as String?,
  );
}
