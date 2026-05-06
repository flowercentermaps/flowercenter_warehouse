import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/stock_check_item.dart';
import '../providers/stock_check_provider.dart';
import '../providers/transfer_action_provider.dart';
import '../widgets/stock_item_card.dart';
import 'pdf_preview_screen.dart';

class StockCheckScreen extends ConsumerWidget {
  final int quotationId;
  const StockCheckScreen({super.key, required this.quotationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state        = ref.watch(stockCheckProvider(quotationId));
    final transferState = ref.watch(transferActionProvider(quotationId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stock Check #$quotationId',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (state.hasValue && (state.valueOrNull ?? []).isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Generate PDF',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PdfPreviewScreen(
                    quotationId: quotationId,
                    items: state.valueOrNull ?? [],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (items) => _Body(
          quotationId: quotationId,
          items: items,
        ),
      ),
      bottomNavigationBar: _BottomBar(
        quotationId: quotationId,
        isLoading: transferState.isLoading,
        allChecked: (state.valueOrNull ?? []).every((i) => i.isChecked),
        itemsLoaded: state.hasValue,
      ),
    );
  }
}

// ── Body ───────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final int quotationId;
  final List<StockCheckItem> items;

  const _Body({required this.quotationId, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Center(child: Text('No items found for this quotation.'));
    }

    final checkedCount = items.where((i) => i.isChecked).length;
    final progress     = checkedCount / items.length;

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$checkedCount / ${items.length} items checked',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: progress == 1.0
                          ? AppConstants.successColor
                          : AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  color: progress == 1.0
                      ? AppConstants.successColor
                      : AppConstants.primaryColor,
                ),
              ),
            ],
          ),
        ),

        // Items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            itemCount: items.length,
            itemBuilder: (ctx, i) => StockItemCard(
              index: i + 1,
              item: items[i],
              onChanged: (updated) => ref
                  .read(stockCheckProvider(quotationId).notifier)
                  .updateItem(updated),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bottom bar ─────────────────────────────────────────────────────────────

class _BottomBar extends ConsumerWidget {
  final int  quotationId;
  final bool isLoading;
  final bool allChecked;
  final bool itemsLoaded;

  const _BottomBar({
    required this.quotationId,
    required this.isLoading,
    required this.allChecked,
    required this.itemsLoaded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!allChecked && itemsLoaded)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Check all items to enable transfer',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600),
              ),
            ),
          isLoading
              ? const CircularProgressIndicator()
              : FilledButton.icon(
                  onPressed: (allChecked && !isLoading)
                      ? () async {
                          final confirmed = await _confirm(context);
                          if (!confirmed || !context.mounted) return;
                          final success = await ref
                              .read(transferActionProvider(quotationId).notifier)
                              .markTransferred();
                          if (!context.mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Marked as Transferred ✓'),
                                backgroundColor: AppConstants.successColor,
                              ),
                            );
                            Navigator.of(context).pop();
                          } else {
                            final err = ref.read(transferActionProvider(quotationId)).error;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $err'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      : null,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Mark as Transferred'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.infoColor,
                    disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
        ],
      ),
    );
  }

  Future<bool> _confirm(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm Transfer'),
            content: const Text(
              'Are you sure all items have been verified and the stock is ready to transfer?\n\nThis will notify the sales team.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.infoColor),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
