import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/formatters.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class SeasonScreen extends StatelessWidget {
  const SeasonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SeasonProvider, AuthProvider>(
      builder: (context, seasonProvider, authProvider, _) {
        if (seasonProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final seasons = seasonProvider.seasons;

        return Scaffold(
          body: seasons.isEmpty
              ? _buildEmptyState(context, authProvider, seasonProvider)
              : _buildSeasonList(context, seasons, seasonProvider),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCreateSeasonDialog(
              context,
              authProvider,
              seasonProvider,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Yeni Sezon'),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AuthProvider authProvider,
    SeasonProvider seasonProvider,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz sezon kaydı yok',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Yeni sezon başlatmak için + butonuna tıklayın'),
        ],
      ),
    );
  }

  Widget _buildSeasonList(
    BuildContext context,
    List<SeasonModel> seasons,
    SeasonProvider seasonProvider,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy', 'tr_TR');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: seasons.length,
      itemBuilder: (context, index) {
        final season = seasons[index];
        final isActive = season.isActive;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isActive
                ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                : BorderSide.none,
          ),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive ? Colors.green : Colors.grey[300],
                  child: Icon(
                    isActive ? Icons.play_arrow : Icons.check,
                    color: isActive ? Colors.white : Colors.grey[600],
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(season.name)),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'AKTİF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  '${dateFormat.format(season.startDate)}${season.endDate != null ? ' - ${dateFormat.format(season.endDate!)}' : ' - Devam ediyor'}',
                ),
                trailing: isActive
                    ? PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'end',
                            child: Row(
                              children: [
                                Icon(Icons.stop, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Sezonu Bitir'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'end') {
                            _showEndSeasonDialog(context, season, seasonProvider);
                          }
                        },
                      )
                    : null,
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Hasat',
                            '${season.totalHarvests}',
                            Icons.eco,
                            Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Toplam Kg',
                            season.totalKg.toPriceString(0),
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
                          child: _buildStatItem(
                            'Brüt Kazanç',
                            '₺${season.totalGrossEarning.toPriceString(0)}',
                            Icons.payments,
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Komisyon',
                            '₺${season.totalCommission.toPriceString(0)}',
                            Icons.remove_circle,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Net Kazanç: ₺${season.totalNetEarning.toPriceString(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              //color: Theme.of(context).primaryColor,
                              color: Colors.lightGreen[700],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCreateSeasonDialog(
    BuildContext context,
    AuthProvider authProvider,
    SeasonProvider seasonProvider,
  ) {
    final controller = TextEditingController();
    final now = DateTime.now();
    controller.text = '${now.year} ${_getSeasonName(now.month)}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Sezon Başlat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (seasonProvider.hasActiveSeason)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mevcut aktif sezon "${seasonProvider.activeSeason!.name}" sonlandırılacak.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Sezon Adı',
                hintText: 'Örn: 2024 İlkbahar',
                border: OutlineInputBorder(),
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
              if (controller.text.isNotEmpty) {
                await seasonProvider.createSeason(
                  authProvider.currentUser!.id,
                  controller.text,
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Başlat'),
          ),
        ],
      ),
    );
  }

  void _showEndSeasonDialog(
    BuildContext context,
    SeasonModel season,
    SeasonProvider seasonProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sezonu Bitir'),
        content: Text(
          '"${season.name}" sezonunu bitirmek istediğinizden emin misiniz?\n\n'
          'Sezon sona erdikten sonra bu sezonda yeni hasat ekleyemezsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await seasonProvider.endSeason(season.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Bitir'),
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
