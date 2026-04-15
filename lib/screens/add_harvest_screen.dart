import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/formatters.dart';
import '../providers/providers.dart';
import '../models/models.dart';

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

  ProductModel? _selectedProduct;

  /// Aktif fiyatı döndürür: Özel fiyat açıksa kullanıcının girdiği fiyat, kapalıysa admin fiyatı
  double get _activePrice {
    if (_useCustomPrice) {
      return double.tryParse(_customPriceController.text) ?? 0;
    }
    return _selectedProduct?.pricePerKg ?? 0;
  }

  @override
  void dispose() {
    _crateCountController.dispose();
    _totalKgController.dispose();
    _notesController.dispose();
    _customPriceController.dispose();
    super.dispose();
  }

  double get _calculatedGross {
    if (_selectedProduct == null) return 0;
    final kg = double.tryParse(_totalKgController.text) ?? 0;
    return kg * _activePrice;
  }

  double get _calculatedCommission {
    final authProvider = context.read<AuthProvider>();
    final rate = authProvider.currentUser?.commissionRate ?? 8.0;
    return _calculatedGross * (rate / 100);
  }

  double get _calculatedNet {
    return _calculatedGross - _calculatedCommission;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ürün seçiniz')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final seasonProvider = context.read<SeasonProvider>();
    final harvestProvider = context.read<HarvestProvider>();

    if (authProvider.currentUser == null || seasonProvider.activeSeason == null) {
      return;
    }

    final priceToUse = _useCustomPrice
        ? double.parse(_customPriceController.text)
        : _selectedProduct!.pricePerKg;

    await harvestProvider.addHarvest(
      userId: authProvider.currentUser!.id,
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      crateCount: int.parse(_crateCountController.text),
      totalKg: double.parse(_totalKgController.text),
      pricePerKg: priceToUse,
      commissionRate: authProvider.currentUser!.commissionRate,
      seasonId: seasonProvider.activeSeason!.id,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    // Sezon toplamlarını güncelle
    await seasonProvider.refreshActiveSeason(authProvider.currentUser!.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hasat başarıyla kaydedildi!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasat Ekle'),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          final products = productProvider.products;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ürün Seçimi
                  DropdownButtonFormField<ProductModel>(
                    value: _selectedProduct,
                    decoration: const InputDecoration(
                      labelText: 'Ürün Seçiniz',
                      prefixIcon: Icon(Icons.eco),
                      border: OutlineInputBorder(),
                    ),
                    items: products.map((product) {
                      return DropdownMenuItem(
                        value: product,
                        child: Text(
                          '${product.name} (₺${product.pricePerKg.toPriceString(2)}/kg)',
                        ),
                      );
                    }).toList(),
                    onChanged: (product) {
                      setState(() {
                        _selectedProduct = product;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Ürün seçiniz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Özel Fiyat Girişi
                  Card(
                    color: _useCustomPrice
                        ? Colors.orange.shade50
                        : Colors.grey[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _useCustomPrice
                            ? Colors.orange.shade300
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Özel Fiyat Kullan',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              _useCustomPrice
                                  ? 'Kendi fiyatınızı giriyorsunuz'
                                  : 'Güncel hal fiyatı kullanılıyor',
                              style: TextStyle(
                                color: _useCustomPrice
                                    ? Colors.orange.shade700
                                    : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            secondary: Icon(
                              _useCustomPrice
                                  ? Icons.edit_note
                                  : Icons.store,
                              color: _useCustomPrice
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                            value: _useCustomPrice,
                            activeColor: Colors.orange,
                            onChanged: (value) {
                              setState(() {
                                _useCustomPrice = value;
                                if (!value) {
                                  _customPriceController.clear();
                                }
                              });
                            },
                          ),
                          if (_useCustomPrice) ...[
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _customPriceController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Kilogram Fiyatı (₺)',
                                labelStyle: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                hintText: _selectedProduct != null
                                    ? 'Güncel fiyat: ₺${_selectedProduct!.pricePerKg.toPriceString(2)}'
                                    : 'Fiyat giriniz',
                                hintStyle: TextStyle(
                                  color: Colors.orange.shade400,
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: const Icon(
                                  Icons.currency_lira,
                                  color: Colors.orange,
                                ),
                                border: const OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.orange.shade400,
                                    width: 2,
                                  ),
                                ),
                                suffixText: '₺/kg',
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if (!_useCustomPrice) return null;
                                if (value == null || value.isEmpty) {
                                  return 'Özel fiyat giriniz';
                                }
                                if (double.tryParse(value) == null ||
                                    double.parse(value) <= 0) {
                                  return 'Geçerli bir fiyat giriniz';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '💡 Hasatı geç giriyorsanız veya farklı bir fiyattan satış yaptıysanız buraya kendi fiyatınızı yazabilirsiniz.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sandık Sayısı
                  TextFormField(
                    controller: _crateCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sandık Sayısı',
                      prefixIcon: Icon(Icons.inventory_2),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Sandık sayısı giriniz';
                      }
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Geçerli bir sayı giriniz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Toplam Kg
                  TextFormField(
                    controller: _totalKgController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Toplam Kilogram',
                      prefixIcon: Icon(Icons.scale),
                      border: OutlineInputBorder(),
                      suffixText: 'kg',
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Toplam kg giriniz';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Geçerli bir değer giriniz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Notlar (Opsiyonel)
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notlar (Opsiyonel)',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Hesaplama Özeti
                  if (_selectedProduct != null &&
                      _totalKgController.text.isNotEmpty) ...[
                    Card(
                      color: Colors.grey[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kazanç Hesabı',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Divider(),
                            _buildCalculationRow(
                              _useCustomPrice
                                  ? 'Kilogram Fiyatı (Özel)'
                                  : 'Kilogram Fiyatı',
                              '₺${_activePrice.toPriceString(2)}',
                              color: _useCustomPrice ? Colors.orange : null,
                            ),
                            _buildCalculationRow(
                              'Brüt Kazanç',
                              '₺${_calculatedGross.toPriceString(2)}',
                            ),
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                return _buildCalculationRow(
                                  'Komisyon (%${auth.currentUser?.commissionRate.toPriceString(1) ?? '8.0'})',
                                  '-₺${_calculatedCommission.toPriceString(2)}',
                                  color: Colors.red,
                                );
                              },
                            ),
                            const Divider(),
                            _buildCalculationRow(
                              'Net Kazanç',
                              '₺${_calculatedNet.toPriceString(2)}',
                              isBold: true,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Kaydet Butonu
                  ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Hasatı Kaydet',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
