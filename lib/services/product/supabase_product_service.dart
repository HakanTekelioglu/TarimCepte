import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import '../contracts/product_service_contract.dart';

/// Supabase ile çalışan ürün servisi
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
        .order('name');
    final List<dynamic> data = response;
    return data.map((json) => ProductModel.fromJson(json)).toList();
  }

  @override
  Future<ProductModel> addProduct(
    String name,
    double pricePerKg,
    String category,
  ) async {
    final response =
        await _client
            .from('products')
            .insert({
              'name': name,
              'price_per_kg': pricePerKg,
              'category': category,
            })
            .select()
            .single();

    return ProductModel.fromJson(response);
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    await _client
        .from('products')
        .update({
          'name': product.name,
          'price_per_kg': product.pricePerKg,
          'category': product.category,
          'updated_at': DateTime.now().toIso8601String(),
          'is_active': product.isActive,
        })
        .eq('id', product.id);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _client
        .from('products')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  @override
  Future<List<ProductModel>> getProductsByLocation(
    String city,
    String? district,
  ) async {
    final productsResponse = await _client
        .from('products')
        .select()
        .eq('is_active', true)
        .order('name');
    final List<ProductModel> baseProducts =
        (productsResponse as List<dynamic>)
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();

    try {
      var query = _client
          .from('product_prices')
          .select('product_id, price_per_kg, updated_at')
          .eq('city', city);

      if (district != null && district.isNotEmpty) {
        query = query.eq('district', district);
      } else {
        query = query.isFilter('district', null);
      }

      final pricesResponse = await query.order('updated_at', ascending: false);
      final pricesMap = <String, double>{};

      for (var row in pricesResponse as List<dynamic>) {
        final productId = row['product_id'] as String;
        // Coklu satir olursa (eski duplicate veriler), en guncel kayit kullanilsin.
        if (!pricesMap.containsKey(productId)) {
          pricesMap[productId] = (row['price_per_kg'] as num).toDouble();
        }
      }

      return baseProducts.map((p) {
        if (pricesMap.containsKey(p.id)) {
          return p.copyWith(pricePerKg: pricesMap[p.id]);
        }
        return p;
      }).toList();
    } catch (e) {
      // Eğer product_prices tablosu henüz oluşturulmadıysa veya hata verirse,
      // orijinal ürünleri (varsayılan fiyatlarıyla) döndür.
      developer.log(
        'Konuma göre ürün fiyatları alınamadı.',
        name: 'SupabaseProductService',
        error: e,
      );
      return baseProducts;
    }
  }

  @override
  Future<void> updateProductPriceLocation(
    String productId,
    String city,
    String? district,
    double newPrice,
  ) async {
    try {
      final nowIso = DateTime.now().toIso8601String();

      var updateQuery = _client
          .from('product_prices')
          .update({'price_per_kg': newPrice, 'updated_at': nowIso})
          .eq('product_id', productId)
          .eq('city', city);

      if (district != null && district.isNotEmpty) {
        updateQuery = updateQuery.eq('district', district);
      } else {
        updateQuery = updateQuery.isFilter('district', null);
      }

      final updatedRows = await updateQuery.select('id');
      final updatedCount = (updatedRows as List<dynamic>).length;

      if (updatedCount == 0) {
        await _client.from('product_prices').insert({
          'product_id': productId,
          'city': city,
          'district': district,
          'price_per_kg': newPrice,
          'updated_at': nowIso,
        });
      }
    } catch (e) {
      developer.log(
        'Konuma göre ürün fiyatı güncellenemedi.',
        name: 'SupabaseProductService',
        error: e,
      );
      throw Exception('Fiyat güncellenirken hata oluştu: $e');
    }
  }
}
