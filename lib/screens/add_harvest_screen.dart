import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  ProductModel? _selectedProduct;

  @override
  void dispose() {
    _crateCountController.dispose();
    _totalKgController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _calculatedGross {
    if (_selectedProduct == null) return 0;
    final kg = double.tryParse(_totalKgController.text) ?? 0;
    return kg * _selectedProduct!.pricePerKg;
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

    await harvestProvider.addHarvest(
      userId: authProvider.currentUser!.id,
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      crateCount: int.parse(_crateCountController.text),
      totalKg: double.parse(_totalKgController.text),
      pricePerKg: _selectedProduct!.pricePerKg,
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
                          '${product.name} (₺${product.pricePerKg.toStringAsFixed(2)}/kg)',
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
                              'Kilogram Fiyatı',
                              '₺${_selectedProduct!.pricePerKg.toStringAsFixed(2)}',
                            ),
                            _buildCalculationRow(
                              'Brüt Kazanç',
                              '₺${_calculatedGross.toStringAsFixed(2)}',
                            ),
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                return _buildCalculationRow(
                                  'Komisyon (%${auth.currentUser?.commissionRate.toStringAsFixed(1) ?? '8.0'})',
                                  '-₺${_calculatedCommission.toStringAsFixed(2)}',
                                  color: Colors.red,
                                );
                              },
                            ),
                            const Divider(),
                            _buildCalculationRow(
                              'Net Kazanç',
                              '₺${_calculatedNet.toStringAsFixed(2)}',
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
