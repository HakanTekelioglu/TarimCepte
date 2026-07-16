import '../../models/product_model.dart';

abstract interface class IProductService {
  Future<List<ProductModel>> getAllProducts();
  Future<ProductModel> addProduct(
    String name,
    double pricePerKg,
    String category,
  );
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
  Future<List<ProductModel>> getProductsByLocation(
    String city,
    String? district,
  );
  Future<void> updateProductPriceLocation(
    String productId,
    String city,
    String? district,
    double newPrice,
  );
}
