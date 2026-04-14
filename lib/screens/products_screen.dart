import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../utils/app_constants.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = context.read<AuthProvider>().currentUser;
      final provider = context.read<ProductProvider>();
      
      final initCity = user?.city ?? AppConstants.cities.first;
      String? initDistrict = user?.district;
      // Valide district
      if (initDistrict != null) {
        final distList = AppConstants.cityDistricts[initCity] ?? [];
        if (!distList.contains(initDistrict)) {
          initDistrict = distList.isNotEmpty ? distList.first : null;
        }
      } else {
        final distList = AppConstants.cityDistricts[initCity] ?? [];
        if (distList.isNotEmpty) initDistrict = distList.first;
      }
      
      // Only load if not already loaded or different
      if (provider.selectedCity != initCity || provider.selectedDistrict != initDistrict || provider.products.isEmpty) {
        Future.microtask(() => provider.loadProductsByLocation(initCity, initDistrict));
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().currentUser?.isAdmin ?? false;

    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        if (productProvider.isLoading || productProvider.selectedCity == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentCity = productProvider.selectedCity!;
        final currentDistrict = productProvider.selectedDistrict;
        
        final districtList = AppConstants.cityDistricts[currentCity] ?? [];

        final products = productProvider.products;
        final vegetables = productProvider.getProductsByCategory('sebze');
        final fruits = productProvider.getProductsByCategory('meyve');

        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              // Location Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: currentCity,
                        decoration: const InputDecoration(labelText: 'İl'),
                        items: AppConstants.cities.map((String c) {
                          return DropdownMenuItem<String>(
                            value: c,
                            child: Text(c),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            String? newDist = null;
                            final dList = AppConstants.cityDistricts[newValue] ?? [];
                            if (dList.isNotEmpty) {
                              newDist = dList.first;
                            }
                            productProvider.loadProductsByLocation(newValue, newDist);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (districtList.isNotEmpty)
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: districtList.contains(currentDistrict) ? currentDistrict : null,
                          decoration: const InputDecoration(labelText: 'İlçe'),
                          items: districtList.map((String d) {
                            return DropdownMenuItem<String>(
                              value: d,
                              child: Text(d),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              productProvider.loadProductsByLocation(currentCity, newValue);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
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
                    _buildProductList(context, products, isAdmin, productProvider),
                    _buildProductList(context, vegetables, isAdmin, productProvider),
                    _buildProductList(context, fruits, isAdmin, productProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductList(BuildContext context, List<ProductModel> products, bool isAdmin, ProductProvider productProvider) {
    if (productProvider.error != null) {
      return Center(child: Text('Hata: ${productProvider.error}', style: const TextStyle(color: Colors.red)));
    }
    if (products.isEmpty) {
      return const Center(child: Text('Bu bölgede ürün bulunamadı.'));
    }

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            title: Text(product.name),
            subtitle: Text(product.category),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${product.pricePerKg.toStringAsFixed(2)} ₺/kg',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
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
    final priceController = TextEditingController(text: product.pricePerKg.toString());
    final provider = context.read<ProductProvider>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${product.name} Fiyatını Güncelle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lokasyon: ${provider.selectedCity} / ${provider.selectedDistrict ?? '-'}', 
                   style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Fiyat (₺)',
                  suffixText: '₺',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final newPrice = double.tryParse(priceController.text);
                if (newPrice != null && newPrice > 0) {
                  provider.updateProductPrice(product.id, newPrice);
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} fiyatı güncellendi ve bu bölge için kaydedildi.')),
                  );
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }
}
