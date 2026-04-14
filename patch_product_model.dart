import 'dart:io';

void main() {
  final file = File('lib/models/product_model.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(
    "pricePerKg: (json['pricePerKg'] as num).toDouble(),",
    "pricePerKg: ((json['price_per_kg'] ?? json['pricePerKg']) as num).toDouble(),"
  );
  content = content.replaceAll(
    "updatedAt: DateTime.parse(json['updatedAt'] as String),",
    "updatedAt: DateTime.parse((json['updated_at'] ?? json['updatedAt']) as String),"
  );
  content = content.replaceAll(
    "isActive: json['isActive'] as bool? ?? true,",
    "isActive: (json['is_active'] ?? json['isActive']) as bool? ?? true,"
  );
  file.writeAsStringSync(content);
}
