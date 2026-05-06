import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/formatters.dart';
import '../providers/providers.dart';
import 'login_screen.dart';
import 'products_screen.dart';
import 'add_harvest_screen.dart';
import 'harvest_history_screen.dart';
import 'season_screen.dart';
import 'settings_screen.dart';

import '../utils/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final productProvider = context.read<ProductProvider>();
    final seasonProvider = context.read<SeasonProvider>();
    final harvestProvider = context.read<HarvestProvider>();

    if (authProvider.currentUser != null) {
      final user = authProvider.currentUser!;
      final initCity = user.city ?? 'Mersin';
      final initDistrict = AppConstants.normalizeDistrict(initCity, user.district);
      
      await productProvider.loadProductsByLocation(initCity, initDistrict);
      await seasonProvider.loadSeasons(user.id);
      
      if (seasonProvider.activeSeason != null) {
        await harvestProvider.loadHarvestsBySeason(seasonProvider.activeSeason!.id);
      } else {
        harvestProvider.clearHarvests();
      }
    } else {
      harvestProvider.clearHarvests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hal Fiyat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final seasonProvider = context.read<SeasonProvider>();
                if (!seasonProvider.hasActiveSeason) {
                  _showCreateSeasonDialog();
                  return;
                }
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddHarvestScreen()),
                );
                _loadData();
              },
              icon: const Icon(Icons.add),
              label: const Text('Hasat Ekle'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.price_change_outlined),
            selectedIcon: Icon(Icons.price_change),
            label: 'Fiyatlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Hasatlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Sezonlar',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const ProductsScreen();
      case 2:
        return const HarvestHistoryScreen();
      case 3:
        return const SeasonScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Consumer4<AuthProvider, SeasonProvider, HarvestProvider, ProductProvider>(
      builder: (context, auth, season, harvest, product, _) {
        final user = auth.currentUser;
        if (user == null) return const SizedBox.shrink();

        return RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Karşılama
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hoş geldin, ${user.fullName}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Komisyon Oranı: %${user.commissionRate.toPriceString(1)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Aktif Sezon Bilgisi
                if (season.activeSeason != null) ...[
                  Text(
                    'Aktif Sezon: ${season.activeSeason!.name}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Kazanç Özeti Kartları
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Toplam Hasat',
                          '${harvest.harvests.length}',
                          Icons.eco,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Toplam Kg',
                          '${harvest.totalKg.toPriceString(1)} kg',
                          Icons.scale,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Brüt Kazanç',
                          '₺${harvest.totalGrossEarning.toPriceString(2)}',
                          Icons.payments,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Komisyon',
                          '₺${harvest.totalCommission.toPriceString(2)}',
                          Icons.remove_circle,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Net Kazanç - Büyük Kart
                  Card(
                    color: Theme.of(context).primaryColor,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Net Kazanç',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '₺${harvest.totalNetEarning.toPriceString(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Aktif sezon yok
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aktif sezon bulunmuyor',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Hasat kaydetmek için yeni bir sezon başlatın',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showCreateSeasonDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Yeni Sezon Başlat'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Son Hasatlar
                if (harvest.harvests.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Son Hasatlar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...harvest.harvests.take(5).map((h) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Icon(Icons.eco, color: Colors.green[700]),
                          ),
                          title: Text(h.productName),
                          subtitle: Text(
                            '${h.crateCount} sandık - ${h.totalKg.toPriceString(1)} kg',
                          ),
                          trailing: Text(
                            '₺${h.netEarning.toPriceString(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSeasonDialog() {
    final controller = TextEditingController();
    final auth = context.read<AuthProvider>();
    final commissionController = TextEditingController(
      text: (auth.currentUser?.commissionRate ?? 8.0).toStringAsFixed(1),
    );
    final now = DateTime.now();
    controller.text = '${now.year} ${_getSeasonName(now.month)}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Sezon Başlat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Sezon Adı',
                hintText: 'Örn: 2024 İlkbahar',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commissionController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Sezon Komisyon Oranı (%)',
                hintText: 'Örn: 8.0',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final commissionRate = double.tryParse(commissionController.text);
              if (controller.text.isNotEmpty &&
                  commissionRate != null &&
                  commissionRate >= 0) {
                final season = context.read<SeasonProvider>();
                await season.createSeason(
                  auth.currentUser!.id,
                  controller.text,
                  commissionRate,
                );
                if (mounted) {
                  Navigator.of(context).pop();
                  _loadData();
                }
              }
            },
            child: const Text('Başlat'),
          ),
        ],
      ),
    );
  }

  String _getSeasonName(int month) {
    if (month >= 3 && month <= 5) return 'İlkbahar';
    if (month >= 6 && month <= 8) return 'Yaz';
    if (month >= 9 && month <= 11) return 'Sonbahar';
    return 'Kış';
  }
}

