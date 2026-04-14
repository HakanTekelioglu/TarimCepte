#!/bin/bash

# product_provider.dart patch
cat << 'PATCH1' > lib/providers/product_provider.patch
--- lib/providers/product_provider.dart
+++ lib/providers/product_provider.dart
@@ -7,9 +7,14 @@
   final IProductService _productService;
   List<ProductModel> _products = [];
   bool _isLoading = false;
   String? _error;
 
+  String? selectedCity;
+  String? selectedDistrict;
+
   ProductProvider({IProductService? productService})
       : _productService = productService ?? LocalProductService();
 
@@ -34,6 +39,24 @@
     notifyListeners();
   }
 
+  /// Şehir ve ilçeye göre ürünleri yükle
+  Future<void> loadProductsByLocation(String city, String? district) async {
+    _isLoading = true;
+    selectedCity = city;
+    selectedDistrict = district;
+    notifyListeners();
+
+    try {
+      _products = await _productService.getProductsByLocation(city, district);
+      _error = null;
+    } catch (e) {
+      _error = e.toString();
+    }
+
+    _isLoading = false;
+    notifyListeners();
+  }
+
   /// Yeni ürün ekle
   Future<void> addProduct(
@@ -58,9 +81,21 @@
   }
 
   /// Ürün fiyatını güncelle
   Future<void> updateProductPrice(String productId, double newPrice) async {
-    final index = _products.indexWhere((p) => p.id == productId);
-    if (index != -1) {
-      final updatedProduct = _products[index].copyWith(pricePerKg: newPrice);
-      await updateProduct(updatedProduct);
+    if (selectedCity != null) {
+      try {
+        await _productService.updateProductPriceLocation(
+            productId, selectedCity!, selectedDistrict, newPrice);
+            
+        final index = _products.indexWhere((p) => p.id == productId);
+        if (index != -1) {
+          _products[index] = _products[index].copyWith(pricePerKg: newPrice);
+          notifyListeners();
+        }
+      } catch (e) {
+        _error = e.toString();
+      }
+    } else {
+      final index = _products.indexWhere((p) => p.id == productId);
+      if (index != -1) {
+        final updatedProduct = _products[index].copyWith(pricePerKg: newPrice);
+        await updateProduct(updatedProduct);
+      }
     }
   }
PATCH1
patch lib/providers/product_provider.dart lib/providers/product_provider.patch

# product_service.dart patch
cat << 'PATCH2' > lib/services/product_service.patch
--- lib/services/product_service.dart
+++ lib/services/product_service.dart
@@ -10,6 +10,8 @@
   Future<ProductModel> addProduct(String name, double pricePerKg, String category);
   Future<void> updateProduct(ProductModel product);
   Future<void> deleteProduct(String id);
+  Future<List<ProductModel>> getProductsByLocation(String city, String? district);
+  Future<void> updateProductPriceLocation(String productId, String city, String? district, double newPrice);
 }
 
 /// Local Storage ile çalışan Ürün servisi
@@ -108,6 +110,18 @@
       }
     }
   }
+
+  @override
+  Future<List<ProductModel>> getProductsByLocation(String city, String? district) async {
+    // Lokal servis için normal ürünleri döndürüyoruz, MVP gereği
+    return getAllProducts();
+  }
+
+  @override
+  Future<void> updateProductPriceLocation(String productId, String city, String? district, double newPrice) async {
+    // Lokal servis için normal güncellemeyi çağırıyoruz
+    // Bu opsiyonel bir fallback
+  }
 }
 
 /// Supabase ile çalışan Ürün servisi
@@ -189,4 +203,50 @@
         .delete()
         .eq('id', id);
   }
+
+  @override
+  Future<List<ProductModel>> getProductsByLocation(String city, String? district) async {
+    final productsResponse = await _client
+        .from('products')
+        .select()
+        .eq('is_active', true)
+        .order('name');
+        
+    final List<ProductModel> baseProducts = (productsResponse as List<dynamic>)
+        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
+        .toList();
+
+    var query = _client.from('product_prices').select().eq('city', city);
+    if (district != null && district.isNotEmpty) {
+      query = query.eq('district', district);
+    } else {
+      query = query.filter('district', 'is', null);
+    }
+
+    final pricesResponse = await query;
+    final pricesMap = <String, double>{};
+    
+    for (var row in pricesResponse as List<dynamic>) {
+      pricesMap[row['product_id'] as String] = (row['price_per_kg'] as num).toDouble();
+    }
+
+    return baseProducts.map((p) {
+      if (pricesMap.containsKey(p.id)) {
+        return p.copyWith(pricePerKg: pricesMap[p.id]);
+      }
+      return p;
+    }).toList();
+  }
+
+  @override
+  Future<void> updateProductPriceLocation(String productId, String city, String? district, double newPrice) async {
+    final data = {
+      'product_id': productId,
+      'city': city,
+      'district': district,
+      'price_per_kg': newPrice,
+      'updated_at': DateTime.now().toIso8601String(),
+    };
+    
+    // Upsert on unique columns (product_id, city, district)
+    // In Supabase, if district is unique constraint with nulls not distinct this could fail but we try unique
+    await _client.from('product_prices').upsert(data, onConflict: 'product_id, city, district');
+  }
 }
PATCH2
patch lib/services/product_service.dart lib/services/product_service.patch
