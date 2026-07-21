import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/services/seen_quotations_service.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../stock_check/presentation/screens/stock_check_screen.dart';
import '../../domain/entities/pending_quotation.dart';
import '../providers/pending_transfers_provider.dart';
import '../widgets/today_stats_chip.dart';

enum _DateFilter { today, yesterday, week, all }

extension on _DateFilter {
  String label(AppLocalizations l) => switch (this) {
        _DateFilter.today     => l.filterToday,
        _DateFilter.yesterday => l.filterYesterday,
        _DateFilter.week      => l.filterThisWeek,
        _DateFilter.all       => l.filterAll,
      };

  bool matches(DateTime d) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final local = d.toLocal();
    final dDay  = DateTime(local.year, local.month, local.day);
    return switch (this) {
      _DateFilter.today     => dDay == today,
      _DateFilter.yesterday => dDay == today.subtract(const Duration(days: 1)),
      _DateFilter.week      => !dDay.isBefore(today.subtract(const Duration(days: 6))),
      _DateFilter.all       => true,
    };
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _searchOpen = false;
  String _query = '';
  _DateFilter _pendingFilter    = _DateFilter.all;
  _DateFilter _transferredFilter = _DateFilter.today;

  int _seenStamp = 0;
  void _bumpSeen() => setState(() => _seenStamp++);

  @override
  Widget build(BuildContext context) {
    final l    = context.l10n;
    final user = ref.watch(authProvider).valueOrNull;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: _searchOpen
              ? _buildSearchField(l)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.homeTitle),
                    if (user != null)
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppConstants.textMuted(context),
                          letterSpacing: 0,
                        ),
                      ),
                  ],
                ),
          actions: [
            IconButton(
              icon: Icon(
                _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                size: 22,
              ),
              tooltip: _searchOpen ? l.tooltipCloseSearch : l.tooltipSearch,
              onPressed: () => setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) _query = '';
              }),
            ),
            if (!_searchOpen) ...[
              const TodayStatsChip(),
              Consumer(builder: (context, ref, _) {
                final mode  = ref.watch(themeModeProvider);
                final isDark = mode == ThemeMode.dark;
                return IconButton(
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    size: 22,
                  ),
                  tooltip: isDark ? l.tooltipLightMode : l.tooltipDarkMode,
                  onPressed: () =>
                      ref.read(themeModeProvider.notifier).toggle(),
                );
              }),
              // Language toggle
              Consumer(builder: (context, ref, _) {
                final l2 = context.l10n;
                return TextButton(
                  onPressed: () =>
                      ref.read(localeProvider.notifier).toggle(),
                  child: Text(
                    l2.tooltipLanguage,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                );
              }),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 22),
                tooltip: l.tooltipRefresh,
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Future.wait([
                    ref.read(pendingTransfersProvider.notifier).refresh(),
                    ref.read(transferredProvider.notifier).refresh(),
                  ]);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l.snackRefreshed),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(milliseconds: 900),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.rMd)),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 22),
                tooltip: l.tooltipSignOut,
                onPressed: () => ref.read(authProvider.notifier).signOut(),
              ),
              const SizedBox(width: AppSpacing.s4),
            ],
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Consumer(builder: (context, ref, _) {
              final l2 = context.l10n;
              final pendingCount =
                  (ref.watch(pendingTransfersProvider).valueOrNull ?? const [])
                      .length;
              final transferredTodayCount = (ref
                          .watch(transferredProvider)
                          .valueOrNull ??
                      const [])
                  .where((q) => _DateFilter.today.matches(q.createdAt))
                  .length;
              return TabBar(
                tabs: [
                  _buildTab(
                    icon: Icons.hourglass_top_rounded,
                    label: l2.tabNewRequests,
                    badge: pendingCount > 0 ? pendingCount.toString() : null,
                    badgeColor: AppConstants.primaryColor,
                  ),
                  _buildTab(
                    icon: Icons.check_circle_outline_rounded,
                    label: l2.tabTransferred,
                    badge: transferredTodayCount > 0
                        ? transferredTodayCount.toString()
                        : null,
                    badgeColor: AppConstants.successColor,
                  ),
                ],
              );
            }),
          ),
        ),
        body: TabBarView(
          children: [
            _QuotationList(
              key: ValueKey('pending-$_seenStamp'),
              provider: pendingTransfersProvider,
              onRefresh: () =>
                  ref.read(pendingTransfersProvider.notifier).refresh(),
              emptyTitle: l.emptyAllClearTitle,
              emptyMessage: l.emptyAllClearMsg,
              emptyIcon: Icons.check_circle_outline_rounded,
              emptyIconColor: AppConstants.successColor,
              transferred: false,
              query: _query,
              filter: _pendingFilter,
              onFilterChanged: (f) => setState(() => _pendingFilter = f),
              onItemOpened: (id) async {
                await SeenQuotationsService.markSeen(id);
                if (mounted) _bumpSeen();
              },
            ),
            _QuotationList(
              key: ValueKey('transferred-$_seenStamp'),
              provider: transferredProvider,
              onRefresh: () =>
                  ref.read(transferredProvider.notifier).refresh(),
              emptyTitle: l.emptyNothingYetTitle,
              emptyMessage: l.emptyNothingYetMsg,
              emptyIcon: Icons.swap_horiz_rounded,
              emptyIconColor: AppConstants.infoColor,
              transferred: true,
              query: _query,
              filter: _transferredFilter,
              onFilterChanged: (f) =>
                  setState(() => _transferredFilter = f),
              onItemOpened: (id) async {
                await SeenQuotationsService.markSeen(id);
                if (mounted) _bumpSeen();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    String? badge,
    Color? badgeColor,
  }) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: AppSpacing.s6),
          Text(label),
          if (badge != null) ...[
            const SizedBox(width: AppSpacing.s6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppConstants.primaryColor)
                    .withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppSpacing.rPill),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: badgeColor ?? AppConstants.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations l) {
    return TextField(
      autofocus: true,
      onChanged: (v) => setState(() => _query = v),
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: l.searchHint,
        hintStyle: TextStyle(
          color: AppConstants.textMuted(context),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

// ── Tab list ─────────────────────────────────────────────────────────────────

class _QuotationList extends ConsumerWidget {
  final AsyncNotifierProvider<dynamic, List<PendingQuotation>> provider;
  final Future<void> Function() onRefresh;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final Color emptyIconColor;
  final bool transferred;
  final String query;
  final _DateFilter filter;
  final ValueChanged<_DateFilter> onFilterChanged;
  final ValueChanged<int> onItemOpened;

  const _QuotationList({
    super.key,
    required this.provider,
    required this.onRefresh,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.emptyIconColor,
    required this.transferred,
    required this.query,
    required this.filter,
    required this.onFilterChanged,
    required this.onItemOpened,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l     = context.l10n;
    final state = ref.watch(provider);

    return state.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppConstants.primaryColor,
        ),
      ),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        iconColor: AppConstants.dangerColor,
        title: l.errorTitle,
        message: e.toString(),
        action: SizedBox(
          width: 140,
          child: FilledButton(
            onPressed: onRefresh,
            child: Text(l.btnRetry),
          ),
        ),
      ),
      data: (list) {
        final filtered = _applyFilters(list);
        return Column(
          children: [
            _FilterBar(active: filter, onChanged: onFilterChanged),
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      icon: query.isNotEmpty
                          ? Icons.search_off_rounded
                          : emptyIcon,
                      iconColor: query.isNotEmpty
                          ? AppConstants.textMuted(context)
                          : emptyIconColor,
                      title: query.isNotEmpty ? l.emptyNoMatchesTitle : emptyTitle,
                      message: query.isNotEmpty ? l.emptyNoMatchesMsg : emptyMessage,
                      footer: list.isEmpty && query.isEmpty
                          ? 'Last checked ${formatRelative(DateTime.now(), l10n: l)}'
                          : null,
                    )
                  : RefreshIndicator(
                      onRefresh: onRefresh,
                      color: AppConstants.primaryColor,
                      strokeWidth: 2.5,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.s16,
                            AppSpacing.s10,
                            AppSpacing.s16,
                            AppSpacing.s32),
                        // Responsive: ~360px per card — 1 column on phones,
                        // 2 on tablets, 3-4 on desktop (was hardcoded to 2,
                        // which stretched two giant cards across a monitor).
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 420,
                          crossAxisSpacing: AppSpacing.s12,
                          mainAxisSpacing: AppSpacing.s12,
                          mainAxisExtent: 178,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final q = filtered[i];
                          return _QuotationCard(
                            quotation: q,
                            transferred: transferred,
                            isUnread: !transferred &&
                                !SeenQuotationsService.isSeen(q.id),
                            onTap: () async {
                              onItemOpened(q.id);
                              await Navigator.of(ctx).push(
                                MaterialPageRoute(
                                  builder: (_) => StockCheckScreen(
                                    quotationId: q.id,
                                    quoteNo: q.quoteNo,
                                    salespersonName: q.salespersonName,
                                    customerName: q.customerName,
                                    deliveryType: q.deliveryType,
                                  ),
                                ),
                              );
                            },
                            onLongPress: () => _showQuickActions(ctx, q, ref),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  List<PendingQuotation> _applyFilters(List<PendingQuotation> list) {
    final q = query.trim().toLowerCase();
    return list.where((p) {
      if (!filter.matches(p.createdAt)) return false;
      if (q.isEmpty) return true;
      return p.customerName.toLowerCase().contains(q) ||
          p.companyName.toLowerCase().contains(q) ||
          p.quoteNo.toLowerCase().contains(q) ||
          p.salespersonName.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _cancelTransfer(
      BuildContext context, PendingQuotation q, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Transfer?'),
        content: Text(
          'This will remove "${q.quoteNo.isNotEmpty ? q.quoteNo : "#${q.id}"}" '
          'from the warehouse queue. The salesperson will need to re-send it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppConstants.dangerColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel Transfer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await Supabase.instance.client
          .from('quotations')
          .update({'transfer_status': null})
          .eq('id', q.id);
      ref.invalidate(pendingTransfersProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showQuickActions(
      BuildContext context, PendingQuotation q, WidgetRef ref) async {
    final l = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final hasPhone = q.customerPhone.trim().isNotEmpty;
        final l2 = ctx.l10n;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.s20,
                    AppSpacing.s4, AppSpacing.s20, AppSpacing.s12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.customerName.isNotEmpty
                                ? q.customerName
                                : (q.companyName.isNotEmpty
                                    ? q.companyName
                                    : l.unknownCustomer),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (q.customerPhone.isNotEmpty)
                            Text(
                              q.customerPhone,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppConstants.textMuted(ctx),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.call_rounded,
                    color: AppConstants.successColor),
                title: Text(l2.btnCallCustomer),
                subtitle: hasPhone ? null : Text(l2.noPhone),
                enabled: hasPhone,
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _launch('tel:${q.customerPhone}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF25D366)),
                title: Text(l2.btnWhatsApp),
                subtitle: hasPhone ? null : Text(l2.noPhone),
                enabled: hasPhone,
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final cleaned =
                      q.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
                  await _launch('https://wa.me/$cleaned');
                },
              ),
              if (!transferred)
                ListTile(
                  leading: const Icon(Icons.cancel_outlined,
                      color: AppConstants.dangerColor),
                  title: const Text('Cancel Transfer',
                      style: TextStyle(color: AppConstants.dangerColor)),
                  subtitle: const Text('Return to CRM queue'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _cancelTransfer(context, q, ref);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: Text(l2.btnCancel),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final _DateFilter active;
  final ValueChanged<_DateFilter> onChanged;

  const _FilterBar({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        itemCount: _DateFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
        itemBuilder: (_, i) {
          final f        = _DateFilter.values[i];
          final selected = f == active;
          return ChoiceChip(
            label: Text(f.label(l)),
            selected: selected,
            onSelected: (_) => onChanged(f),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : AppConstants.textMuted(context),
            ),
          );
        },
      ),
    );
  }
}

// ── Quotation card ────────────────────────────────────────────────────────────

class _QuotationCard extends StatelessWidget {
  final PendingQuotation quotation;
  final bool transferred;
  final bool isUnread;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _QuotationCard({
    required this.quotation,
    required this.transferred,
    required this.isUnread,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final l         = context.l10n;
    final dateStr   = DateFormat('dd MMM yyyy · HH:mm')
        .format(quotation.createdAt.toLocal());
    final relativeStr = formatRelative(quotation.createdAt, l10n: l);
    final moneyFmt  = NumberFormat('#,##0.00');
    final accentColor =
        transferred ? AppConstants.successColor : AppConstants.warningColor;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s16,
                  AppSpacing.s14, AppSpacing.s16, AppSpacing.s14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatusChip(transferred: transferred),
                      const SizedBox(width: 8),
                      _CardDeliveryBadge(deliveryType: quotation.deliveryType),
                      if (quotation.urgent && !transferred) ...[
                        const SizedBox(width: 8),
                        const _UrgentBadge(),
                      ],
                      const Spacer(),
                      Text(
                        quotation.quoteNo.isNotEmpty
                            ? quotation.quoteNo
                            : '#${quotation.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.primaryColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s10),
                  Text(
                    quotation.customerName.isNotEmpty
                        ? quotation.customerName
                        : l.unknownCustomer,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (quotation.companyName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      quotation.companyName,
                      style: TextStyle(
                        color: AppConstants.textMuted(context),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (quotation.salespersonName.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s8),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 13,
                            color: AppConstants.textMuted(context)),
                        const SizedBox(width: AppSpacing.s4),
                        Flexible(
                          child: Text(
                            quotation.salespersonName,
                            style: TextStyle(
                              color: AppConstants.textMuted(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s12),
                  Divider(
                    height: 1,
                    color: AppConstants.goldBorder(context),
                  ),
                  const SizedBox(height: AppSpacing.s10),
                  Row(
                    children: [
                      Text(
                        'AED ${moneyFmt.format(quotation.netTotal)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: accentColor,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.inventory_2_outlined,
                          size: 13,
                          color: AppConstants.textFaint(context)),
                      const SizedBox(width: AppSpacing.s4),
                      Text(
                        '${quotation.itemCount} items',
                        style: TextStyle(
                          color: AppConstants.textMuted(context),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Tooltip(
                        message: dateStr,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 13,
                                color: AppConstants.textFaint(context)),
                            const SizedBox(width: AppSpacing.s4),
                            Text(
                              relativeStr,
                              style: TextStyle(
                                color: AppConstants.textMuted(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      Icon(Icons.chevron_right_rounded,
                          size: 18,
                          color: AppConstants.textFaint(context)),
                    ],
                  ),
                ],
              ),
            ),
            if (isUnread)
              Positioned(
                left: 4,
                top: 8,
                bottom: 8,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.rPill),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool transferred;
  const _StatusChip({required this.transferred});

  @override
  Widget build(BuildContext context) {
    final l     = context.l10n;
    final color = transferred ? AppConstants.successColor : AppConstants.warningColor;
    final icon  = transferred
        ? Icons.check_circle_outline_rounded
        : Icons.hourglass_top_rounded;
    final label = transferred ? l.statusTransferredChip : l.statusPendingChip;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.rPill),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: AppSpacing.s4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Red URGENT badge — shown on requests the salesperson flagged as urgent.
class _UrgentBadge extends StatelessWidget {
  const _UrgentBadge();

  @override
  Widget build(BuildContext context) {
    final fg = Colors.red.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high_rounded, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(
            context.l10n.urgentBadge,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: fg,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDeliveryBadge extends StatelessWidget {
  final DeliveryType deliveryType;
  const _CardDeliveryBadge({required this.deliveryType});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (deliveryType) {
      DeliveryType.inside  => (
          const Color(0xFF2196F3).withValues(alpha: 0.12),
          const Color(0xFF1565C0),
          Icons.home_rounded,
        ),
      DeliveryType.outside => (
          const Color(0xFFFF9800).withValues(alpha: 0.12),
          const Color(0xFFE65100),
          Icons.local_shipping_rounded,
        ),
      DeliveryType.none    => (
          Colors.grey.withValues(alpha: 0.10),
          Colors.grey.shade600,
          Icons.store_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            deliveryType.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
