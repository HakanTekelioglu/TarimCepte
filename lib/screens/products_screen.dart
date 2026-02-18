import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().currentUser?.isAdmin ?? false;
    
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        if (productProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = productProvider.products;
        final vegetables = productProvider.getProductsByCategory('sebze');
        final fruits = productProvider.getProductsByCategory('meyve');

        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Tümü'),
                  Tab(text: 'Sebzeler'),
                  Tab(text: 'Meyveler'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildProductList(context, products, isAdmin),
                    _buildProductList(context, vegetables, isAdmin),
                    _buildProductList(context, fruits, isAdmin),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductList(BuildContext context, List<ProductModel> products, bool isAdmin) {
    if (products.isEmpty) {
      return const Center(
        child: Text('Bu kategoride ürün bulunmuyor'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: product.category == 'meyve'
                  ? Colors.orange[100]
                  : Colors.green[100],
              child: Icon(
                product.category == 'meyve' ? Icons.apple : Icons.eco,
                color: product.category == 'meyve'
                    ? Colors.orange[700]
                    : Colors.green[700],
              ),
            ),
            title: Text(product.name),
            subtitle: Text(product.category == 'meyve' ? 'Meyve' : 'Sebze'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₺${product.pricePerKg.toStringAsFixed(2)}/kg',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Sadece admin fiyat düzenleyebilir
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditPriceDialog(context, product),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditPriceDialog(BuildContext context, ProductModel product) {
    final controller = TextEditingController(
      text: product.pricePerKg.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${product.name} Fiyatı'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Kilogram Fiyatı (₺)',
            prefixIcon: Icon(Icons.payments),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null && newPrice > 0) {
                context
                    .read<ProductProvider>()
                    .updateProductPrice(product.id, newPrice);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
