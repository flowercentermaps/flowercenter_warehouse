import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../stock_check/presentation/screens/stock_check_screen.dart';
import '../../domain/entities/pending_quotation.dart';
import '../providers/pending_transfers_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Warehouse',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              if (user != null)
                Text(
                  user.name,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w400),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: () {
                ref.read(pendingTransfersProvider.notifier).refresh();
                ref.read(transferredProvider.notifier).refresh();
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sign out',
              onPressed: () => ref.read(authProvider.notifier).signOut(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.hourglass_top_rounded, size: 16),
                text: 'New Requests',
              ),
              Tab(
                icon: Icon(Icons.check_circle_outline_rounded, size: 16),
                text: 'Transferred',
              ),
            ],
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
        body: TabBarView(
          children: [
            _QuotationList(
              provider: pendingTransfersProvider,
              onRefresh: () =>
                  ref.read(pendingTransfersProvider.notifier).refresh(),
              emptyMessage: 'No pending transfers right now.',
              emptyIcon: Icons.check_circle_outline_rounded,
              transferred: false,
            ),
            _QuotationList(
              provider: transferredProvider,
              onRefresh: () =>
                  ref.read(transferredProvider.notifier).refresh(),
              emptyMessage: 'No transferred quotations yet.',
              emptyIcon: Icons.swap_horiz_rounded,
              transferred: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab list ───────────────────────────────────────────────────────────────

class _QuotationList extends ConsumerWidget {
  final AsyncNotifierProvider<dynamic, List<PendingQuotation>> provider;
  final Future<void> Function() onRefresh;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool transferred;

  const _QuotationList({
    required this.provider,
    required this.onRefresh,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.transferred,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(e.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (list) => list.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(emptyIcon,
                      size: 72,
                      color: AppConstants.successColor.withValues(alpha: 0.6)),
                  const SizedBox(height: 16),
                  Text(
                    transferred ? 'Nothing here yet' : 'All clear!',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(emptyMessage,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: onRefresh,
              color: AppConstants.primaryColor,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _QuotationCard(
                  quotation: list[i],
                  transferred: transferred,
                  onTap: () => Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          StockCheckScreen(quotationId: list[i].id),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ── Quotation card ─────────────────────────────────────────────────────────

class _QuotationCard extends StatelessWidget {
  final PendingQuotation quotation;
  final bool transferred;
  final VoidCallback onTap;

  const _QuotationCard({
    required this.quotation,
    required this.transferred,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(quotation.createdAt);
    final moneyFmt = NumberFormat('#,##0.00');
    final accentColor =
        transferred ? AppConstants.successColor : AppConstants.warningColor;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusChip(transferred: transferred),
                        const Spacer(),
                        Text(
                          quotation.quoteNo.isNotEmpty
                              ? quotation.quoteNo
                              : '#${quotation.id}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      quotation.customerName.isNotEmpty
                          ? quotation.customerName
                          : 'Unknown Customer',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (quotation.companyName.isNotEmpty)
                      Text(
                        quotation.companyName,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'AED ${moneyFmt.format(quotation.netTotal)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        const Spacer(),
                        const Icon(Icons.inventory_2_outlined,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${quotation.itemCount} items',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.calendar_today_outlined,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool transferred;
  const _StatusChip({required this.transferred});

  @override
  Widget build(BuildContext context) {
    final color =
        transferred ? AppConstants.successColor : AppConstants.warningColor;
    final icon = transferred
        ? Icons.check_circle_outline_rounded
        : Icons.hourglass_top_rounded;
    final label = transferred ? 'Transferred' : 'Pending Transfer';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
