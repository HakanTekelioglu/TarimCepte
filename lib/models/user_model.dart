/// Kullanıcı modeli
class UserModel {
  final String id;
  final String phoneNumber;
  final String? email;
  final String fullName;
  final double commissionRate; // Komisyoncu kesinti oranı (%)
  final DateTime createdAt;
  final bool isAdmin; // Admin yetkisi
  final String? city;
  final String? district;

  UserModel({
    required this.id,
    required this.phoneNumber,
    this.email,
    required this.fullName,
    this.commissionRate = 8.0, // Varsayılan %
    required this.createdAt,
    this.isAdmin = false, // Varsayılan olarak admin değil
    this.city,
    this.district,
  });

  /// JSON'dan model oluştur
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phoneNumber: (json['phoneNumber'] ?? json['email']) as String,
      email: json['email'] as String?,
      fullName: json['fullName'] as String,
      commissionRate: (json['commissionRate'] as num?)?.toDouble() ?? 8.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isAdmin: json['isAdmin'] as bool? ?? false,
      city: json['city'] as String?,
      district: json['district'] as String?,
    );
  }

  /// Modeli JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'email': email,
      'fullName': fullName,
      'commissionRate': commissionRate,
      'createdAt': createdAt.toIso8601String(),
      'isAdmin': isAdmin,
      'city': city,
      'district': district,
    };
  }

  /// Güncellenmiş kopya oluştur
  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? email,
    String? fullName,
    double? commissionRate,
    DateTime? createdAt,
    bool? isAdmin,
    String? city,
    String? district,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      commissionRate: commissionRate ?? this.commissionRate,
      createdAt: createdAt ?? this.createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
      city: city ?? this.city,
      district: district ?? this.district,
    );
  }
}
