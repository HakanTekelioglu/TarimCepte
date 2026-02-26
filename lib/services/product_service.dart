import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'supabase_mapper.dart';

/// Ürün servisi interface'i
/// Firebase entegrasyonu için hazır altyapı
abstract class IProductService {
  Future<List<ProductModel>> getAllProducts();
  Future<ProductModel?> getProductById(String id);
  Future<ProductModel> addProduct(String name, double pricePerKg, String category);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
}

/// Local Storage ile çalışan Product servisi
class LocalProductService implements IProductService {
  static const String _productsKey = 'products';
  final Uuid _uuid = const Uuid();

  // Varsayılan ürünler
  final List<Map<String, dynamic>> _defaultProducts = [
    {'name': 'Salatalık', 'pricePerKg': 75.0, 'category': 'sebze'},
    {'name': 'Sivri Biber', 'pricePerKg': 60.0, 'category': 'sebze'},
    {'name': 'Patlıcan', 'pricePerKg': 55.0, 'category': 'sebze'},
    {'name': 'kıl Biber', 'pricePerKg': 110.0, 'category': 'sebze'},
    {'name': 'Fasulye', 'pricePerKg': 115.0, 'category': 'sebze'},
    {'name': 'Domates', 'pricePerKg': 35.0, 'category': 'sebze'},
    {'name': 'Muz', 'pricePerKg': 50.0, 'category': 'meyve'},
    {'name': 'Çilek', 'pricePerKg': 120.0, 'category': 'meyve'},
    {'name': 'Üzüm', 'pricePerKg': 80.0, 'category': 'meyve'},
    {'name': 'Şeftali', 'pricePerKg': 65.0, 'category': 'meyve'},
    {'name': 'Erik', 'pricePerKg': 50.0, 'category': 'meyve'},
  ];

  @override
  Future<List<ProductModel>> getAllProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(_productsKey);

    if (productsJson == null) {
      // Varsayılan ürünleri oluştur
      await _initializeDefaultProducts();
      return getAllProducts();
    }

    final List<dynamic> products = jsonDecode(productsJson);
    return products
        .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
        .where((p) => p.isActive)
        .toList();
  }

  Future<void> _initializeDefaultProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final products = _defaultProducts.map((p) {
      return ProductModel(
        id: _uuid.v4(),
        name: p['name'] as String,
        pricePerKg: p['pricePerKg'] as double,
        category: p['category'] as String,
        updatedAt: DateTime.now(),
      ).toJson();
    }).toList();

    await prefs.setString(_productsKey, jsonEncode(products));
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    final products = await getAllProducts();
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ProductModel> addProduct(
      String name, double pricePerKg, String category) async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(_productsKey);

    List<dynamic> products = [];
    if (productsJson != null) {
      products = jsonDecode(productsJson);
    }

    final newProduct = ProductModel(
      id: _uuid.v4(),
      name: name,
      pricePerKg: pricePerKg,
      category: category,
      updatedAt: DateTime.now(),
    );

    products.add(newProduct.toJson());
    await prefs.setString(_productsKey, jsonEncode(products));

    return newProduct;
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(_productsKey);

    if (productsJson == null) return;

    final List<dynamic> products = jsonDecode(productsJson);
    for (int i = 0; i < products.length; i++) {
      if ((products[i] as Map<String, dynamic>)['id'] == product.id) {
        products[i] = product.copyWith(updatedAt: DateTime.now()).toJson();
        break;
      }
    }

    await prefs.setString(_productsKey, jsonEncode(products));
  }

  @override
  Future<void> deleteProduct(String id) async {
    final product = await getProductById(id);
    if (product != null) {
      await updateProduct(product.copyWith(isActive: false));
    }
  }
}

/// Supabase ile çalışan Product servisi
class SupabaseProductService implements IProductService {
  final SupabaseClient _client;

  SupabaseProductService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<ProductModel>> getAllProducts() async {
    final response = await _client
        .from('products')
        .select()
        .eq('is_active', true)
        .order('updated_at', ascending: false);

    return (response as List<dynamic>)
        .map((item) => productFromDbMap(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    final response = await _client
        .from('products')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return productFromDbMap(response);
  }

  @override
  Future<ProductModel> addProduct(
    String name,
    double pricePerKg,
    String category,
  ) async {
    final product = ProductModel(
      id: const Uuid().v4(),
      name: name,
      pricePerKg: pricePerKg,
      category: category,
      updatedAt: DateTime.now(),
    );

    final response = await _client
        .from('products')
        .insert(productToDbMap(product))
        .select()
        .single();

    return productFromDbMap(response);
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final updated = product.copyWith(updatedAt: DateTime.now());
    await _client
        .from('products')
        .update(productToDbMap(updated))
        .eq('id', product.id);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _client
        .from('products')
        .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
