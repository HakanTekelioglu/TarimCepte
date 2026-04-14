import 'dart:io';

void main() {
  final content = File('lib/providers/product_provider.dart').readAsStringSync();
  final modified = content
      .replaceFirst('String? _error;', '''String? _error;
  String? selectedCity;
  String? selectedDistrict;''')
      .replaceFirst('  /// Yeni ürün ekle', '''  /// Şehir ve ilçeye göre ürünleri yükle
  Future<void> loadProductsByLocation(String city, String? district) async {
    _isLoading = true;
    selectedCity = city;
    selectedDistrict = district;
    notifyListeners();

    try {
      _products = await _productService.getProductsByLocation(city, district);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Yeni ürün ekle''')
      .replaceFirst('''  /// Ürün fiyatını güncelle
  Future<void> updateProductPrice(String productId, double newPrice) async {    
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final updatedProduct = _products[index].copyWith(pricePerKg: newPrice);   
      await updateProduct(updatedProduct);
    }
  }''', '''  /// Ürün fiyatını güncelle
  Future<void> updateProductPrice(String productId, double newPrice) async {
    if (selectedCity != null) {
      try {
        await _productService.updateProductPriceLocation(
            productId, selectedCity!, selectedDistrict, newPrice);
            
        final index = _products.indexWhere((p) => p.id == productId);
        if (index != -1) {
          _products[index] = _products[index].copyWith(pricePerKg: newPrice);
          notifyListeners();
        }
      } catch (e) {
        _error = e.toString();
      }
    } else {
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final updatedProduct = _products[index].copyWith(pricePerKg: newPrice);
        await updateProduct(updatedProduct);
      }
    }
  }''');
  File('lib/providers/product_provider.dart').writeAsStringSync(modified);
}
