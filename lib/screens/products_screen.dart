import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_constants.dart';
import '../utils/formatters.dart';
import '../widgets/app_ui.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();
  bool _initialized = false;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final user = context.read<AuthProvider>().currentUser;
    final provider = context.read<ProductProvider>();
    final city = user?.city ?? AppConstants.cities.first;
    final district = AppConstants.normalizeDistrict(city, user?.district);

    if (provider.selectedCity != city ||
        provider.selectedDistrict != district ||
        provider.products.isEmpty) {
      Future.microtask(() => provider.loadProductsByLocation(city, district));
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().currentUser?.isAdmin ?? false;

    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if ((provider.isLoading || provider.selectedCity == null) &&
            provider.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final city = provider.selectedCity ?? AppConstants.cities.first;
        final district = provider.selectedDistrict;
        final products = _filterProducts(provider.products);
        final vegetables =
            products.where((product) => product.category == 'sebze').toList();
        final fruits =
            products.where((product) => product.category == 'meyve').toList();

        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              AppContent(
                maxWidth: 960,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _buildFilters(context, provider, city, district),
              ),
              TabBar(
                tabs: [
                  Tab(text: 'Tümü (${products.length})'),
                  Tab(text: 'Sebzeler (${vegetables.length})'),
                  Tab(text: 'Meyveler (${fruits.length})'),
                ],
              ),
              Expanded(
                child:
                    provider.error != null && provider.products.isEmpty
                        ? AppErrorState(
                          message: provider.error!,
                          onRetry:
                              () => provider.loadProductsByLocation(
                                city,
                                district,
                              ),
                        )
                        : Stack(
                          children: [
                            TabBarView(
                              children: [
                                _buildProductList(
                                  context,
                                  products,
                                  isAdmin,
                                  provider,
                                ),
                                _buildProductList(
                                  context,
                                  vegetables,
                                  isAdmin,
                                  provider,
                                ),
                                _buildProductList(
                                  context,
                                  fruits,
                                  isAdmin,
                                  provider,
                                ),
                              ],
                            ),
                            if (provider.isLoading)
                              const Align(
                                alignment: Alignment.topCenter,
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                          ],
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters(
    BuildContext context,
    ProductProvider provider,
    String city,
    String? district,
  ) {
    final colors = Theme.of(context).colorScheme;
    final districts = AppConstants.cityDistricts[city] ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppTonalIcon(
                  icon: Icons.location_on_outlined,
                  size: 40,
                  iconSize: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bölge ve Ürün Ara',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Fiyatlar seçtiğiniz hal bölgesine göre gösterilir.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final showSideBySide = constraints.maxWidth >= 540;
                final fieldWidth =
                    showSideBySide
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: DropdownButtonFormField<String>(
                        initialValue: city,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'İl',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                        items:
                            AppConstants.cities
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            provider.isLoading
                                ? null
                                : (newCity) {
                                  if (newCity == null) return;
                                  final newDistricts =
                                      AppConstants.cityDistricts[newCity] ?? [];
                                  provider.loadProductsByLocation(
                                    newCity,
                                    newDistricts.firstOrNull,
                                  );
                                },
                      ),
                    ),
                    if (districts.isNotEmpty)
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('$city-$district'),
                          initialValue:
                              districts.contains(district) ? district : null,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'İlçe',
                            prefixIcon: Icon(Icons.map_outlined),
                          ),
                          items:
                              districts
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              provider.isLoading
                                  ? null
                                  : (newDistrict) {
                                    if (newDistrict != null) {
                                      provider.loadProductsByLocation(
                                        city,
                                        newDistrict,
                                      );
                                    }
                                  },
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Ürün ara',
                hintText: 'Örn. domates',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon:
                    _query.isEmpty
                        ? null
                        : IconButton(
                          tooltip: 'Aramayı temizle',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ],
        ),
      ),
    );
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    if (_query.isEmpty) return products;
    final normalizedQuery = _query.toLowerCase();
    return products
        .where(
          (product) =>
              product.name.toLowerCase().contains(normalizedQuery) ||
              product.category.toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }

  Widget _buildProductList(
    BuildContext context,
    List<ProductModel> products,
    bool isAdmin,
    ProductProvider provider,
  ) {
    if (products.isEmpty) {
      return AppEmptyState(
        icon: _query.isEmpty ? Icons.inventory_2_outlined : Icons.search_off,
        title: _query.isEmpty ? 'Bu bölgede ürün yok' : 'Sonuç bulunamadı',
        message:
            _query.isEmpty
                ? 'Başka bir il veya ilçe seçerek fiyatları kontrol edebilirsiniz.'
                : 'Farklı bir ürün adı deneyin veya aramayı temizleyin.',
        actionLabel: _query.isEmpty ? null : 'Aramayı Temizle',
        onAction:
            _query.isEmpty
                ? null
                : () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding =
            constraints.maxWidth > 992
                ? (constraints.maxWidth - 960) / 2
                : 16.0;
        return RefreshIndicator(
          onRefresh:
              () => provider.loadProductsByLocation(
                provider.selectedCity!,
                provider.selectedDistrict,
              ),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              88,
            ),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(context, product, isAdmin);
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    ProductModel product,
    bool isAdmin,
  ) {
    final colors = Theme.of(context).colorScheme;
    final isFruit = product.category == 'meyve';
    final categoryColor = isFruit ? colors.tertiary : colors.primary;

    return Semantics(
      button: isAdmin,
      label:
          '${product.name}, kilogram fiyatı ${product.pricePerKg.toPriceString(2)} Türk lirası',
      child: Card(
        child: ListTile(
          onTap: isAdmin ? () => _showEditPriceDialog(product) : null,
          leading: AppTonalIcon(
            icon: isFruit ? Icons.apple_outlined : Icons.eco_outlined,
            color: categoryColor,
          ),
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${_categoryLabel(product.category)}  •  '
            '${DateFormat('d MMM, HH:mm', 'tr_TR').format(product.updatedAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${product.pricePerKg.toPriceString(2)} ₺/kg',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: '${product.name} fiyatını düzenle',
                  onPressed: () => _showEditPriceDialog(product),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    return switch (category.toLowerCase()) {
      'meyve' => 'Meyve',
      'sebze' => 'Sebze',
      _ => category,
    };
  }

  Future<void> _showEditPriceDialog(ProductModel product) async {
    final priceController = TextEditingController(
      text: product.pricePerKg.toPriceString(2),
    );
    final formKey = GlobalKey<FormState>();
    final provider = context.read<ProductProvider>();

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            icon: const Icon(Icons.price_change_outlined),
            title: Text('${product.name} Fiyatı'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${provider.selectedCity} / ${provider.selectedDistrict ?? 'Tüm ilçeler'}',
                    style: TextStyle(
                      color:
                          Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Kilogram Fiyatı',
                      prefixIcon: Icon(Icons.currency_lira_rounded),
                      suffixText: '₺/kg',
                    ),
                    validator: (value) {
                      final price = double.tryParse(
                        (value ?? '').trim().replaceAll(',', '.'),
                      );
                      return price == null || price <= 0
                          ? 'Sıfırdan büyük bir fiyat giriniz'
                          : null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final newPrice = double.parse(
                    priceController.text.trim().replaceAll(',', '.'),
                  );
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await provider.updateProductPrice(product.id, newPrice);
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('${product.name} fiyatı güncellendi.'),
                      ),
                    );
                  } catch (_) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          provider.error ??
                              'Fiyat güncellenemedi. Lütfen tekrar deneyin.',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Fiyatı Kaydet'),
              ),
            ],
          ),
    );

    priceController.dispose();
  }
}
