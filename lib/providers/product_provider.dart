import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Ürün state yönetimi
class ProductProvider extends ChangeNotifier {
  final IProductService _productService;
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;
  String? selectedCity;
  String? selectedDistrict;

  ProductProvider({IProductService? productService})
      : _productService = productService ?? LocalProductService();

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Kategoriye göre ürünler
  List<ProductModel> getProductsByCategory(String category) {
    return _products.where((p) => p.category == category).toList();
  }

  /// Tüm ürünleri yükle
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _productService.getAllProducts();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Şehir ve ilçeye göre ürünleri yükle
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

  /// Yeni ürün ekle
  Future<void> addProduct(
      String name, double pricePerKg, String category) async {
    try {
      final product = await _productService.addProduct(name, pricePerKg, category);
      _products.add(product);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Ürün güncelle
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _productService.updateProduct(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product.copyWith(updatedAt: DateTime.now());
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Ürün fiyatını güncelle
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
  }

  /// Ürün sil
  Future<void> deleteProduct(String id) async {
    try {
      await _productService.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
