import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/formatters.dart';
import '../widgets/app_ui.dart';

class HarvestHistoryScreen extends StatelessWidget {
  final VoidCallback? onAddHarvest;

  const HarvestHistoryScreen({super.key, this.onAddHarvest});

  @override
  Widget build(BuildContext context) {
    return Consumer<HarvestProvider>(
      builder: (context, harvestProvider, _) {
        if (harvestProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (harvestProvider.error != null && harvestProvider.harvests.isEmpty) {
          return AppErrorState(
            message: harvestProvider.error!,
            onRetry: () => _refresh(context),
          );
        }

        final harvests = harvestProvider.harvests;
        if (harvests.isEmpty) {
          return AppEmptyState(
            icon: Icons.eco_outlined,
            title: 'Henüz hasat kaydı yok',
            message:
                'İlk hasadınızı eklediğinizde miktar ve kazanç özetleri burada görünecek.',
            actionLabel: onAddHarvest == null ? null : 'İlk Hasadı Ekle',
            onAction: onAddHarvest,
          );
        }

        final groupedHarvests = _groupByDate(harvests);
        return RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              AppContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummary(context, harvestProvider),
                    const SizedBox(height: 24),
                    const AppSectionHeader(
                      title: 'Kayıtlar',
                      subtitle: 'Detayları görmek için bir hasadı açın',
                    ),
                    const SizedBox(height: 12),
                    ...groupedHarvests.entries.map(
                      (entry) =>
                          _buildDateGroup(context, entry.key, entry.value),
                    ),
                    const SizedBox(height: 88),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, List<HarvestModel>> _groupByDate(List<HarvestModel> harvests) {
    final grouped = <String, List<HarvestModel>>{};
    final dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');
    for (final harvest in harvests) {
      grouped.putIfAbsent(dateFormat.format(harvest.harvestDate), () => []);
      grouped[dateFormat.format(harvest.harvestDate)]!.add(harvest);
    }
    return grouped;
  }

  Widget _buildSummary(BuildContext context, HarvestProvider provider) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sezon Hasat Özeti',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: colors.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 540;
              final items = [
                _SummaryItem(
                  label: 'Kayıt',
                  value: '${provider.harvests.length}',
                  icon: Icons.eco_outlined,
                ),
                _SummaryItem(
                  label: 'Toplam',
                  value: '${provider.totalKg.toPriceString(1)} kg',
                  icon: Icons.scale_outlined,
                ),
                _SummaryItem(
                  label: 'Net Kazanç',
                  value: '₺${provider.totalNetEarning.toPriceString(2)}',
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ];

              if (compact) {
                return Column(
                  children:
                      items
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildSummaryItem(
                                context,
                                item,
                                expanded: true,
                              ),
                            ),
                          )
                          .toList(),
                );
              }

              return Row(
                children:
                    items
                        .map(
                          (item) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildSummaryItem(context, item),
                            ),
                          ),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    _SummaryItem item, {
    bool expanded = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: expanded ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 20, color: colors.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.value,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroup(
    BuildContext context,
    String date,
    List<HarvestModel> harvests,
  ) {
    final colors = Theme.of(context).colorScheme;
    final dayTotal = harvests.fold<double>(
      0,
      (sum, harvest) => sum + harvest.netEarning,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  'Gün toplamı  ₺${dayTotal.toPriceString(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: colors.primary),
                ),
              ],
            ),
          ),
          ...harvests.map(
            (harvest) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Dismissible(
                key: Key(harvest.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(context, harvest),
                onDismissed: (_) => _deleteHarvest(context, harvest),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: colors.onErrorContainer,
                  ),
                ),
                child: Card(
                  child: ExpansionTile(
                    leading: const AppTonalIcon(icon: Icons.eco_outlined),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            harvest.productName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₺${harvest.netEarning.toPriceString(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${harvest.crateCount} sandık  •  '
                      '${harvest.totalKg.toPriceString(1)} kg',
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      const Divider(),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        context,
                        'Birim Fiyat',
                        '₺${harvest.pricePerKg.toPriceString(2)}/kg',
                      ),
                      _buildDetailRow(
                        context,
                        'Brüt Kazanç',
                        '₺${harvest.grossEarning.toPriceString(2)}',
                      ),
                      _buildDetailRow(
                        context,
                        'Komisyon (%${harvest.commissionRate.toPriceString(1)})',
                        '-₺${harvest.commissionAmount.toPriceString(2)}',
                        color: colors.error,
                      ),
                      const Divider(height: 20),
                      _buildDetailRow(
                        context,
                        'Net Kazanç',
                        '₺${harvest.netEarning.toPriceString(2)}',
                        isBold: true,
                        color: colors.primary,
                      ),
                      if (harvest.notes != null &&
                          harvest.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.notes_rounded,
                                size: 19,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(harvest.notes!)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            if (await _confirmDelete(context, harvest)) {
                              if (context.mounted) {
                                await _deleteHarvest(context, harvest);
                              }
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colors.error,
                          ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Kaydı Sil'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    HarvestModel harvest,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(dialogContext).colorScheme.error,
                ),
                title: const Text('Hasat kaydı silinsin mi?'),
                content: Text(
                  '${harvest.productName} kaydı ve bu kayda ait kazanç bilgileri silinecek.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Vazgeç'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(dialogContext).colorScheme.error,
                      foregroundColor:
                          Theme.of(dialogContext).colorScheme.onError,
                    ),
                    child: const Text('Kaydı Sil'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _deleteHarvest(
    BuildContext context,
    HarvestModel harvest,
  ) async {
    final harvestProvider = context.read<HarvestProvider>();
    final authProvider = context.read<AuthProvider>();
    final seasonProvider = context.read<SeasonProvider>();
    final messenger = ScaffoldMessenger.of(context);

    await harvestProvider.deleteHarvest(harvest.id);
    final user = authProvider.currentUser;
    if (user != null) await seasonProvider.loadSeasons(user.id);
    messenger.showSnackBar(
      SnackBar(content: Text('${harvest.productName} kaydı silindi.')),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final activeSeason = context.read<SeasonProvider>().activeSeason;
    if (activeSeason != null) {
      await context.read<HarvestProvider>().loadHarvestsBySeason(
        activeSeason.id,
      );
    }
  }
}

class _SummaryItem {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}
