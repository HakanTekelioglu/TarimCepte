import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _commissionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _commissionController.text = user.commissionRate.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _commissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;
          if (user == null) return const SizedBox.shrink();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profil Bilgileri
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profil Bilgileri',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Ad Soyad'),
                        subtitle: Text(user.fullName),
                        contentPadding: EdgeInsets.zero,
                      ),
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: const Text('Telefon'),
                        subtitle: Text(user.phoneNumber),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (user.isAdmin)
                        ListTile(
                          leading: const Icon(Icons.admin_panel_settings, color: Colors.orange),
                          title: const Text('Yetki'),
                          subtitle: const Text('Admin'),
                          contentPadding: EdgeInsets.zero,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ADMİN',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Komisyon Ayarları
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Komisyon Ayarları',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Komisyoncunuzun uyguladığı kesinti oranını buradan ayarlayabilirsiniz.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commissionController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Komisyon Oranı',
                                suffixText: '%',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              final rate =
                                  double.tryParse(_commissionController.text);
                              if (rate != null && rate >= 0 && rate <= 100) {
                                authProvider.updateCommissionRate(rate);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Komisyon oranı güncellendi'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Geçerli bir oran giriniz (0-100)'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text('Kaydet'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Hızlı Seçim Butonları
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [5.0, 8.0, 10.0, 12.0, 15.0].map((rate) {
                          final isSelected = user.commissionRate == rate;
                          return ChoiceChip(
                            label: Text('%$rate'),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _commissionController.text =
                                    rate.toStringAsFixed(1);
                                authProvider.updateCommissionRate(rate);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Uygulama Hakkında
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uygulama Hakkında',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Divider(),
                      const ListTile(
                        leading: Icon(Icons.info),
                        title: Text('Versiyon'),
                        subtitle: Text('1.0.0'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const ListTile(
                        leading: Icon(Icons.agriculture),
                        title: Text('Hal Fiyat'),
                        subtitle: Text(
                          'Çiftçiler için gelir takip uygulaması. '
                          'Hasatlarınızı kaydedin, kazançlarınızı takip edin.',
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
