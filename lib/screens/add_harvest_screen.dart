import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_constants.dart';
import '../utils/formatters.dart';
import '../widgets/app_ui.dart';

class AddHarvestScreen extends StatefulWidget {
  const AddHarvestScreen({super.key});

  @override
  State<AddHarvestScreen> createState() => _AddHarvestScreenState();
}

class _AddHarvestScreenState extends State<AddHarvestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _crateCountController = TextEditingController();
  final _totalKgController = TextEditingController();
  final _notesController = TextEditingController();
  final _customPriceController = TextEditingController();

  bool _useCustomPrice = false;
  bool _isSaving = false;
  ProductModel? _selectedProduct;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadProductsForUserLocation);
  }

  @override
  void dispose() {
    _crateCountController.dispose();
    _totalKgController.dispose();
    _notesController.dispose();
    _customPriceController.dispose();
    super.dispose();
  }

  double? _parseDecimal(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  double get _activePrice {
    if (_useCustomPrice) {
      return _parseDecimal(_customPriceController.text) ?? 0;
    }
    return _selectedProduct?.pricePerKg ?? 0;
  }

  double get _calculatedGross {
    final kg = _parseDecimal(_totalKgController.text) ?? 0;
    return kg * _activePrice;
  }

  double get _calculatedCommission {
    final rate =
        context.read<SeasonProvider>().activeSeason?.commissionRate ?? 8.0;
    return _calculatedGross * (rate / 100);
  }

  double get _calculatedNet => _calculatedGross - _calculatedCommission;

  Future<void> _loadProductsForUserLocation() async {
    final authProvider = context.read<AuthProvider>();
    final productProvider = context.read<ProductProvider>();
    final user = authProvider.currentUser;
    final city = user?.city ?? AppConstants.cities.first;
    final district = AppConstants.normalizeDistrict(city, user?.district);

    if (productProvider.selectedCity != city ||
        productProvider.selectedDistrict != district ||
        productProvider.products.isEmpty) {
      await productProvider.loadProductsByLocation(city, district);
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) return;

    final authProvider = context.read<AuthProvider>();
    final seasonProvider = context.read<SeasonProvider>();
    final harvestProvider = context.read<HarvestProvider>();
    final user = authProvider.currentUser;
    final season = seasonProvider.activeSeason;

    if (user == null || season == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hasat eklemek için aktif bir sezon gerekiyor.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final price =
        _useCustomPrice
            ? _parseDecimal(_customPriceController.text)!
            : _selectedProduct!.pricePerKg;

    await harvestProvider.addHarvest(
      userId: user.id,
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      crateCount: int.parse(_crateCountController.text),
      totalKg: _parseDecimal(_totalKgController.text)!,
      pricePerKg: price,
      commissionRate: season.commissionRate,
      seasonId: season.id,
      notes:
          _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
    );

    await seasonProvider.refreshActiveSeason(user.id);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (harvestProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hasat kaydedilemedi. Lütfen bağlantınızı kontrol edip tekrar deneyin.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedProduct!.name} hasadı kaydedildi.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Hasat')),
      body: Consumer2<ProductProvider, SeasonProvider>(
        builder: (context, productProvider, seasonProvider, _) {
          if (productProvider.isLoading && productProvider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productProvider.error != null &&
              productProvider.products.isEmpty) {
            return AppErrorState(
              message: productProvider.error!,
              onRetry: _loadProductsForUserLocation,
            );
          }

          if (productProvider.products.isEmpty) {
            return const AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Bu bölgede ürün bulunamadı',
              message:
                  'Hasat ekleyebilmek için seçili bölgeye ait en az bir ürün gerekiyor.',
            );
          }

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: AppContent(
              maxWidth: 760,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSeasonBanner(context, seasonProvider),
                    const SizedBox(height: 16),
                    _buildProductAndPriceCard(
                      context,
                      productProvider.products,
                    ),
                    const SizedBox(height: 16),
                    _buildAmountCard(context),
                    const SizedBox(height: 16),
                    _buildNotesCard(context),
                    const SizedBox(height: 16),
                    _buildCalculationCard(context, seasonProvider),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 728),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  icon:
                      _isSaving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.check_rounded),
                  label: Text(_isSaving ? 'Kaydediliyor…' : 'Hasadı Kaydet'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonBanner(
    BuildContext context,
    SeasonProvider seasonProvider,
  ) {
    final colors = Theme.of(context).colorScheme;
    final season = seasonProvider.activeSeason;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_outlined, color: colors.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  season?.name ?? 'Aktif sezon',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Komisyon oranı: %${season?.commissionRate.toPriceString(1) ?? '8,0'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onPrimaryContainer.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductAndPriceCard(
    BuildContext context,
    List<ProductModel> products,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(
              title: 'Ürün ve Fiyat',
              subtitle: 'Hasadın hangi ürün ve fiyatla hesaplanacağını seçin',
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<ProductModel>(
              initialValue: _selectedProduct,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Ürün',
                prefixIcon: Icon(Icons.eco_outlined),
              ),
              items:
                  products
                      .map(
                        (product) => DropdownMenuItem(
                          value: product,
                          child: Text(
                            '${product.name}  •  ₺${product.pricePerKg.toPriceString(2)}/kg',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (product) {
                setState(() => _selectedProduct = product);
              },
              validator: (value) => value == null ? 'Ürün seçiniz' : null,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color:
                    _useCustomPrice
                        ? colors.tertiaryContainer.withValues(alpha: 0.5)
                        : colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    secondary: Icon(
                      _useCustomPrice
                          ? Icons.edit_note_rounded
                          : Icons.storefront_outlined,
                    ),
                    title: const Text(
                      'Farklı bir fiyat kullan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      _useCustomPrice
                          ? 'Girdiğiniz özel fiyat kullanılacak'
                          : 'Bölgenin güncel ürün fiyatı kullanılacak',
                    ),
                    value: _useCustomPrice,
                    onChanged: (value) {
                      setState(() {
                        _useCustomPrice = value;
                        if (!value) _customPriceController.clear();
                      });
                    },
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 180),
                    crossFadeState:
                        _useCustomPrice
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: TextFormField(
                        controller: _customPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Özel Kilogram Fiyatı',
                          hintText:
                              _selectedProduct == null
                                  ? 'Fiyat giriniz'
                                  : 'Güncel: ₺${_selectedProduct!.pricePerKg.toPriceString(2)}',
                          prefixIcon: const Icon(Icons.currency_lira_rounded),
                          suffixText: '₺/kg',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (!_useCustomPrice) return null;
                          final price = _parseDecimal(value ?? '');
                          if (price == null || price <= 0) {
                            return 'Sıfırdan büyük bir fiyat giriniz';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(
              title: 'Hasat Miktarı',
              subtitle: 'Sandık ve toplam kilogram bilgisini girin',
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final sideBySide = constraints.maxWidth >= 540;
                final fieldWidth =
                    sideBySide
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: TextFormField(
                        controller: _crateCountController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Sandık Sayısı',
                          hintText: 'Örn. 12',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                          suffixText: 'sandık',
                        ),
                        validator: (value) {
                          final count = int.tryParse((value ?? '').trim());
                          return count == null || count <= 0
                              ? 'Geçerli bir sayı giriniz'
                              : null;
                        },
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: TextFormField(
                        controller: _totalKgController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Toplam Kilogram',
                          hintText: 'Örn. 245,5',
                          prefixIcon: Icon(Icons.scale_outlined),
                          suffixText: 'kg',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          final kg = _parseDecimal(value ?? '');
                          return kg == null || kg <= 0
                              ? 'Geçerli bir miktar giriniz'
                              : null;
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(
              title: 'Not',
              subtitle: 'İsteğe bağlı açıklama ekleyebilirsiniz',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Örn. sabah teslim edildi',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationCard(
    BuildContext context,
    SeasonProvider seasonProvider,
  ) {
    final colors = Theme.of(context).colorScheme;
    final rate = seasonProvider.activeSeason?.commissionRate ?? 8.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kazanç Özeti',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: colors.onPrimaryContainer),
          ),
          const SizedBox(height: 14),
          _buildCalculationRow(
            context,
            _useCustomPrice ? 'Kilogram fiyatı (özel)' : 'Kilogram fiyatı',
            '₺${_activePrice.toPriceString(2)}',
          ),
          _buildCalculationRow(
            context,
            'Brüt kazanç',
            '₺${_calculatedGross.toPriceString(2)}',
          ),
          _buildCalculationRow(
            context,
            'Komisyon (%${rate.toPriceString(1)})',
            '-₺${_calculatedCommission.toPriceString(2)}',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              color: colors.onPrimaryContainer.withValues(alpha: 0.18),
            ),
          ),
          _buildCalculationRow(
            context,
            'Net kazanç',
            '₺${_calculatedNet.toPriceString(2)}',
            isEmphasized: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(
    BuildContext context,
    String label,
    String value, {
    bool isEmphasized = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.onPrimaryContainer.withValues(
                  alpha: isEmphasized ? 1 : 0.72,
                ),
                fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: (isEmphasized
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.bodyLarge)
                ?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
