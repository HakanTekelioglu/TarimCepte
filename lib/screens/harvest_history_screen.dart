import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/formatters.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class HarvestHistoryScreen extends StatelessWidget {
  const HarvestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HarvestProvider>(
      builder: (context, harvestProvider, _) {
        if (harvestProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final harvests = harvestProvider.harvests;

        if (harvests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.eco_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz hasat kaydı yok',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text('Yeni hasat eklemek için + butonuna tıklayın'),
              ],
            ),
          );
        }

        // Tarihe göre grupla
        final Map<String, List<HarvestModel>> groupedHarvests = {};
        final dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');

        for (var harvest in harvests) {
          final dateKey = dateFormat.format(harvest.harvestDate);
          if (!groupedHarvests.containsKey(dateKey)) {
            groupedHarvests[dateKey] = [];
          }
          groupedHarvests[dateKey]!.add(harvest);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedHarvests.length,
          itemBuilder: (context, index) {
            final date = groupedHarvests.keys.elementAt(index);
            final dayHarvests = groupedHarvests[date]!;
            final dayTotal = dayHarvests.fold<double>(
              0,
              (sum, h) => sum + h.netEarning,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarih başlığı
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        date,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                      ),
                      Text(
                        '₺${dayTotal.toPriceString(2)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                      ),
                    ],
                  ),
                ),
                // Hasat kartları
                ...dayHarvests.map((harvest) => Dismissible(
                      key: Key(harvest.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Hasatı Sil'),
                            content: const Text(
                              'Bu hasat kaydını silmek istediğinizden emin misiniz?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('İptal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Sil'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) async {
                        final harvestProvider = context.read<HarvestProvider>();
                        final authProvider = context.read<AuthProvider>();
                        final seasonProvider = context.read<SeasonProvider>();
                        final messenger = ScaffoldMessenger.of(context);

                        await harvestProvider.deleteHarvest(harvest.id);

                        final user = authProvider.currentUser;
                        if (user != null) {
                          await seasonProvider.loadSeasons(user.id);
                        }

                        messenger.showSnackBar(
                          const SnackBar(content: Text('Hasat silindi')),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Icon(Icons.eco, color: Colors.green[700]),
                          ),
                          title: Text(harvest.productName),
                          subtitle: Text(
                            '${harvest.crateCount} sandık - ${harvest.totalKg.toPriceString(1)} kg',
                          ),
                          trailing: Text(
                            '₺${harvest.netEarning.toPriceString(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildDetailRow(
                                    'Birim Fiyat',
                                    '₺${harvest.pricePerKg.toPriceString(2)}/kg',
                                  ),
                                  _buildDetailRow(
                                    'Brüt Kazanç',
                                    '₺${harvest.grossEarning.toPriceString(2)}',
                                  ),
                                  _buildDetailRow(
                                    'Komisyon (%${harvest.commissionRate.toPriceString(1)})',
                                    '-₺${harvest.commissionAmount.toPriceString(2)}',
                                    color: Colors.red,
                                  ),
                                  const Divider(),
                                  _buildDetailRow(
                                    'Net Kazanç',
                                    '₺${harvest.netEarning.toPriceString(2)}',
                                    isBold: true,
                                    color: Colors.green,
                                  ),
                                  if (harvest.notes != null) ...[
                                    const Divider(),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.note, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(harvest.notes!)),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value,
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
