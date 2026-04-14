import 'dart:io';

void main() {
  final content = File('lib/services/product_service.dart').readAsStringSync();
  final modified = content.replaceFirst('''    }
  }

  /// Supabase ile çalışan Product servisi''', '''    }
  }

  @override
  Future<List<ProductModel>> getProductsByLocation(String city, String? district) async {
    return getAllProducts();
  }

  @override
  Future<void> updateProductPriceLocation(String productId, String city, String? district, double newPrice) async {}
}

  /// Supabase ile çalışan Product servisi''');
  File('lib/services/product_service.dart').writeAsStringSync(modified);
}
