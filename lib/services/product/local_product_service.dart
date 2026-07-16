import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../contracts/product_service_contract.dart';

/// Local Storage ile çalışan ürün servisi
class LocalProductService implements IProductService {
  static const String _productsKey = 'products';
  final Uuid _uuid = const Uuid();

  @override
  Future<List<ProductModel>> getAllProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(_productsKey);

    if (productsJson == null) {
      final initialProducts = [
        ProductModel(
          id: _uuid.v4(),
          name: 'Salatalık',
          pricePerKg: 75.0,
          updatedAt: DateTime.now(),
          category: 'sebze',
        ),
        ProductModel(
          id: _uuid.v4(),
          name: 'Sivri Biber',
          pricePerKg: 60.0,
          updatedAt: DateTime.now(),
          category: 'sebze',
        ),
      ];
      await prefs.setString(
        _productsKey,
        jsonEncode(initialProducts.map((p) => p.toJson()).toList()),
      );
      return initialProducts;
    }

    final List<dynamic> decoded = jsonDecode(productsJson);
    return decoded
        .map((json) => ProductModel.fromJson(json))
        .where((p) => p.isActive)
        .toList();
  }

  @override
  Future<ProductModel> addProduct(
    String name,
    double pricePerKg,
    String category,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    var products = await getAllProducts();

    final newProduct = ProductModel(
      id: _uuid.v4(),
      name: name,
      pricePerKg: pricePerKg,
      category: category,
      updatedAt: DateTime.now(),
    );
    products.add(newProduct);

    await prefs.setString(
      _productsKey,
      jsonEncode(products.map((p) => p.toJson()).toList()),
    );
    return newProduct;
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(_productsKey);
    if (productsJson != null) {
      final List<dynamic> decoded = jsonDecode(productsJson);
      final products =
          decoded.map((json) => ProductModel.fromJson(json)).toList();

      final index = products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        products[index] = product;
        await prefs.setString(
          _productsKey,
          jsonEncode(products.map((p) => p.toJson()).toList()),
        );
      }
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(_productsKey);
    if (productsJson != null) {
      final List<dynamic> decoded = jsonDecode(productsJson);
      final products =
          decoded.map((json) => ProductModel.fromJson(json)).toList();

      final index = products.indexWhere((p) => p.id == id);
      if (index != -1) {
        products[index] = products[index].copyWith(isActive: false);
        await prefs.setString(
          _productsKey,
          jsonEncode(products.map((p) => p.toJson()).toList()),
        );
      }
    }
  }

  @override
  Future<List<ProductModel>> getProductsByLocation(
    String city,
    String? district,
  ) async {
    return getAllProducts();
  }

  @override
  Future<void> updateProductPriceLocation(
    String productId,
    String city,
    String? district,
    double newPrice,
  ) async {
    // Lokal servis opsiyonel kalsın
  }
}
