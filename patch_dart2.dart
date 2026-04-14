import 'dart:io';
void main() {
  final content = File('lib/services/product_service.dart').readAsStringSync();
  final index = content.lastIndexOf('}');
  final newMethods = '''
  @override
  Future<List<ProductModel>> getProductsByLocation(String city, String? district) async {
    final productsResponse = await _client
        .from('products')
        .select()
        .eq('is_active', true)
        .order('name');
        
    final List<ProductModel> baseProducts = (productsResponse as List<dynamic>)
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();

    var query = _client.from('product_prices').select().eq('city', city);
    if (district != null && district.isNotEmpty) {
      query = query.eq('district', district);
    } else {
      query = query.filter('district', 'is', null);
    }

    final pricesResponse = await query;
    final pricesMap = <String, double>{};
    
    for (var row in pricesResponse as List<dynamic>) {
      pricesMap[row['product_id'] as String] = (row['price_per_kg'] as num).toDouble();
    }

    return baseProducts.map((p) {
      if (pricesMap.containsKey(p.id)) {
        return p.copyWith(pricePerKg: pricesMap[p.id]);
      }
      return p;
    }).toList();
  }

  @override
  Future<void> updateProductPriceLocation(String productId, String city, String? district, double newPrice) async {
    final data = {
      'product_id': productId,
      'city': city,
      'district': district,
      'price_per_kg': newPrice,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _client.from('product_prices').upsert(data, onConflict: 'product_id, city, district');
  }
}''';
  final modified = content.substring(0, index) + newMethods;
  File('lib/services/product_service.dart').writeAsStringSync(modified);
}
