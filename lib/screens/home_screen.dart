import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/providers.dart';
import '../utils/app_constants.dart';
import '../utils/formatters.dart';
import '../widgets/app_ui.dart';
import 'add_harvest_screen.dart';
import 'harvest_history_screen.dart';
import 'login_screen.dart';
import 'products_screen.dart';
import 'season_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _pageTitles = [
    'Genel Bakış',
    'Hal Fiyatları',
    'Hasat Geçmişi',
    'Sezonlar',
  ];

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.space_dashboard_outlined),
      selectedIcon: Icon(Icons.space_dashboard_rounded),
      label: 'Ana Sayfa',
    ),
    NavigationDestination(
      icon: Icon(Icons.price_change_outlined),
      selectedIcon: Icon(Icons.price_change),
      label: 'Fiyatlar',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history_rounded),
      label: 'Hasatlar',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month_rounded),
      label: 'Sezonlar',
    ),
  ];

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

    if (authProvider.currentUser == null) {
      harvestProvider.clearHarvests();
      return;
    }

    final user = authProvider.currentUser!;
    final city = user.city ?? 'Mersin';
    final district = AppConstants.normalizeDistrict(city, user.district);

    await Future.wait([
      productProvider.loadProductsByLocation(city, district),
      seasonProvider.loadSeasons(user.id),
    ]);

    if (seasonProvider.activeSeason != null) {
      await harvestProvider.loadHarvestsBySeason(
        seasonProvider.activeSeason!.id,
      );
    } else {
      harvestProvider.clearHarvests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useNavigationRail = constraints.maxWidth >= 840;
        return Scaffold(
          appBar: AppBar(
            title: Text(_pageTitles[_currentIndex]),
            actions: [
              IconButton(
                tooltip: 'Ayarlar',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              IconButton(
                tooltip: 'Çıkış yap',
                icon: const Icon(Icons.logout_rounded),
                onPressed: _confirmLogout,
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Row(
            children: [
              if (useNavigationRail) ...[
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _selectPage,
                  labelType: NavigationRailLabelType.all,
                  groupAlignment: -0.82,
                  destinations:
                      _destinations
                          .map(
                            (destination) => NavigationRailDestination(
                              icon: destination.icon,
                              selectedIcon: destination.selectedIcon,
                              label: Text(destination.label),
                            ),
                          )
                          .toList(),
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(child: _buildBody()),
            ],
          ),
          floatingActionButton:
              _currentIndex == 0 || _currentIndex == 2
                  ? FloatingActionButton.extended(
                    tooltip: 'Yeni hasat kaydı ekle',
                    onPressed: _openAddHarvest,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Hasat Ekle'),
                  )
                  : null,
          bottomNavigationBar:
              useNavigationRail
                  ? null
                  : NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: _selectPage,
                    destinations: _destinations,
                  ),
        );
      },
    );
  }

  void _selectPage(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  Widget _buildBody() {
    return switch (_currentIndex) {
      0 => _buildDashboard(),
      1 => const ProductsScreen(),
      2 => HarvestHistoryScreen(onAddHarvest: _openAddHarvest),
      3 => const SeasonScreen(),
      _ => _buildDashboard(),
    };
  }

  Widget _buildDashboard() {
    return Consumer4<
      AuthProvider,
      SeasonProvider,
      HarvestProvider,
      ProductProvider
    >(
      builder: (context, auth, season, harvest, product, _) {
        final user = auth.currentUser;
        if (user == null) return const SizedBox.shrink();

        return RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: AppContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(context, user),
                  const SizedBox(height: 24),
                  if (season.activeSeason != null) ...[
                    AppSectionHeader(
                      title: season.activeSeason!.name,
                      subtitle: 'Aktif sezon özeti',
                      trailing: Chip(
                        avatar: const Icon(Icons.bolt_rounded, size: 17),
                        label: const Text('Aktif'),
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        side: BorderSide.none,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildStatsGrid(context, harvest),
                    const SizedBox(height: 12),
                    _buildNetEarningCard(context, harvest),
                  ] else ...[
                    _buildNoSeasonCard(context),
                  ],
                  if (harvest.harvests.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    AppSectionHeader(
                      title: 'Son Hasatlar',
                      subtitle: 'En güncel 5 hasat kaydınız',
                      trailing: TextButton(
                        onPressed: () => _selectPage(2),
                        child: const Text('Tümünü Gör'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...harvest.harvests
                        .take(5)
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              child: ListTile(
                                onTap: () => _selectPage(2),
                                leading: const AppTonalIcon(
                                  icon: Icons.eco_outlined,
                                ),
                                title: Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  '${DateFormat('d MMM', 'tr_TR').format(item.harvestDate)}  •  '
                                  '${item.crateCount} sandık  •  '
                                  '${item.totalKg.toPriceString(1)} kg',
                                ),
                                trailing: Text(
                                  '₺${item.netEarning.toPriceString(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                  const SizedBox(height: 88),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(BuildContext context, UserModel user) {
    final colors = Theme.of(context).colorScheme;
    final location = [
      user.district,
      user.city,
    ].whereType<String>().where((value) => value.isNotEmpty).join(', ');

    return Semantics(
      container: true,
      label: 'Kullanıcı özeti',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primaryContainer,
              colors.tertiaryContainer.withValues(alpha: 0.72),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: colors.onPrimary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hoş geldin, ${user.fullName}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bugünkü kazanç ve hasat durumun burada.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onPrimaryContainer.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoPill(
                        context,
                        Icons.percent_rounded,
                        'Komisyon %${user.commissionRate.toPriceString(1)}',
                      ),
                      if (location.isNotEmpty)
                        _buildInfoPill(
                          context,
                          Icons.location_on_outlined,
                          location,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill(BuildContext context, IconData icon, String label) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, HarvestProvider harvest) {
    final colors = Theme.of(context).colorScheme;
    final items = [
      (
        'Toplam Hasat',
        '${harvest.harvests.length}',
        Icons.eco_outlined,
        colors.primary,
      ),
      (
        'Toplam Miktar',
        '${harvest.totalKg.toPriceString(1)} kg',
        Icons.scale_outlined,
        colors.secondary,
      ),
      (
        'Brüt Kazanç',
        '₺${harvest.totalGrossEarning.toPriceString(2)}',
        Icons.payments_outlined,
        colors.tertiary,
      ),
      (
        'Komisyon',
        '₺${harvest.totalCommission.toPriceString(2)}',
        Icons.receipt_long_outlined,
        colors.error,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 760 ? 4 : 2;
        const gap = 12.0;
        final cardWidth =
            (constraints.maxWidth - (gap * (columnCount - 1))) / columnCount;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children:
              items
                  .map(
                    (item) => SizedBox(
                      width: cardWidth,
                      child: _buildStatCard(
                        context,
                        item.$1,
                        item.$2,
                        item.$3,
                        item.$4,
                      ),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '$title: $value',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTonalIcon(icon: icon, color: color, size: 40, iconSize: 20),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetEarningCard(BuildContext context, HarvestProvider harvest) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label:
          'Net kazanç: ${harvest.totalNetEarning.toPriceString(2)} Türk lirası',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.onPrimary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: colors.onPrimary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Kazanç',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onPrimary.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '₺${harvest.totalNetEarning.toPriceString(2)}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: colors.onPrimary),
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

  Widget _buildNoSeasonCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppEmptyState(
          icon: Icons.calendar_today_outlined,
          title: 'Aktif sezon bulunmuyor',
          message:
              'Hasat kaydetmek ve kazançları takip etmek için yeni bir sezon başlatın.',
          actionLabel: 'Yeni Sezon Başlat',
          onAction: _showCreateSeasonDialog,
        ),
      ),
    );
  }

  Future<void> _openAddHarvest() async {
    final seasonProvider = context.read<SeasonProvider>();
    if (!seasonProvider.hasActiveSeason) {
      await _showCreateSeasonDialog();
      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddHarvestScreen()));
    if (mounted) await _loadData();
  }

  Future<void> _showCreateSeasonDialog() async {
    final nameController = TextEditingController();
    final auth = context.read<AuthProvider>();
    final season = context.read<SeasonProvider>();
    final commissionController = TextEditingController(
      text: (auth.currentUser?.commissionRate ?? 8.0).toStringAsFixed(1),
    );
    final formKey = GlobalKey<FormState>();
    final now = DateTime.now();
    nameController.text = '${now.year} ${_getSeasonName(now.month)}';

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            icon: const Icon(Icons.calendar_month_outlined),
            title: const Text('Yeni Sezon Başlat'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sezon bilgileri yeni hasatların hesaplamalarında kullanılacak.',
                      style: TextStyle(
                        color:
                            Theme.of(
                              dialogContext,
                            ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Sezon Adı',
                        hintText: 'Örn. 2026 Yaz',
                        prefixIcon: Icon(Icons.eco_outlined),
                      ),
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Sezon adı giriniz'
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: commissionController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Komisyon Oranı',
                        hintText: 'Örn. 8,0',
                        prefixIcon: Icon(Icons.percent_rounded),
                        suffixText: '%',
                      ),
                      validator: (value) {
                        final rate = double.tryParse(
                          (value ?? '').trim().replaceAll(',', '.'),
                        );
                        if (rate == null || rate < 0 || rate > 100) {
                          return '0 ile 100 arasında bir oran giriniz';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
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
                  final rate = double.parse(
                    commissionController.text.trim().replaceAll(',', '.'),
                  );
                  await season.createSeason(
                    auth.currentUser!.id,
                    nameController.text.trim(),
                    rate,
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  await _loadData();
                },
                child: const Text('Sezonu Başlat'),
              ),
            ],
          ),
    );

    nameController.dispose();
    commissionController.dispose();
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            icon: const Icon(Icons.logout_rounded),
            title: const Text('Çıkış yapılsın mı?'),
            content: const Text(
              'Hesabınızdan çıkış yapacaksınız. Kaydedilmiş verileriniz silinmez.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Çıkış Yap'),
              ),
            ],
          ),
    );

    if (shouldLogout != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _getSeasonName(int month) {
    if (month >= 3 && month <= 5) return 'İlkbahar';
    if (month >= 6 && month <= 8) return 'Yaz';
    if (month >= 9 && month <= 11) return 'Sonbahar';
    return 'Kış';
  }
}
