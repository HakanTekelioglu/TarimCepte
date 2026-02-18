/// Kullanıcı modeli
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final double commissionRate; // Komisyoncu kesinti oranı (%)
  final DateTime createdAt;
  final bool isAdmin; // Admin yetkisi

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.commissionRate = 8.0, // Varsayılan %
    required this.createdAt,
    this.isAdmin = false, // Varsayılan olarak admin değil
  });

  /// JSON'dan model oluştur
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      commissionRate: (json['commissionRate'] as num?)?.toDouble() ?? 8.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }

  /// Modeli JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'commissionRate': commissionRate,
      'createdAt': createdAt.toIso8601String(),
      'isAdmin': isAdmin,
    };
  }

  /// Güncellenmiş kopya oluştur
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    double? commissionRate,
    DateTime? createdAt,
    bool? isAdmin,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      commissionRate: commissionRate ?? this.commissionRate,
      createdAt: createdAt ?? this.createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
