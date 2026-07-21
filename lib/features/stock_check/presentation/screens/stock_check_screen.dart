import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/save_status_chip.dart';
import '../../domain/entities/check_status.dart';
import '../../domain/entities/stock_check_item.dart';
import '../../domain/repositories/stock_check_repository.dart';
import '../providers/stock_check_provider.dart';
import '../providers/transfer_action_provider.dart';
import '../widgets/stock_check_history_sheet.dart';
import '../widgets/stock_item_card.dart' show StockItemCard, StockTableHeader;
import '../../../pending_transfers/domain/entities/pending_quotation.dart'
    show DeliveryType;
import 'barcode_scanner_screen.dart';
import 'pdf_preview_screen.dart';

class StockCheckScreen extends ConsumerStatefulWidget {
  final int quotationId;
  final String salespersonName;
  final String customerName;
  final String quoteNo;
  final DeliveryType deliveryType;

  const StockCheckScreen({
    super.key,
    required this.quotationId,
    this.salespersonName = '',
    this.customerName = '',
    this.quoteNo = '',
    this.deliveryType = DeliveryType.none,
  });

  @override
  ConsumerState<StockCheckScreen> createState() => _StockCheckScreenState();
}

class _StockCheckScreenState extends ConsumerState<StockCheckScreen> {
  String _query = '';
  bool _searchOpen = false;

  /// ID of the item to highlight (gold ring) after a successful scan.
  /// `_Body` watches this notifier and scrolls the matching card into view.
  final ValueNotifier<int?> _flashId = ValueNotifier<int?>(null);

  @override
  void initState() {
    super.initState();
    // Warehouse "seen" receipt — records that this manager opened the
    // quotation so the CRM shows a "Seen by warehouse — <name>" chip to the
    // salesperson. The RPC no-ops server-side for non-warehouse roles;
    // failures (e.g. DB without the function yet) are deliberately ignored.
    () async {
      try {
        await Supabase.instance.client.rpc('record_quotation_view',
            params: {'p_quotation_id': widget.quotationId});
      } catch (_) {}
    }();
  }

  @override
  void dispose() {
    _flashId.dispose();
    super.dispose();
  }

  Future<void> _cancelTransfer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Transfer?'),
        content: const Text(
          'This will remove the quotation from the warehouse queue. '
          'The salesperson will need to re-send it.',
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
    if (confirmed != true || !mounted) return;
    try {
      await Supabase.instance.client
          .from('quotations')
          .update({'transfer_status': null})
          .eq('id', widget.quotationId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _openScanner(List<StockCheckItem> rawItems) async {
    final messenger = ScaffoldMessenger.of(context);
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null || code.isEmpty || !mounted) return;

    final normalized = code.trim().toUpperCase();
    StockCheckItem? match;
    for (final i in rawItems) {
      if (i.barcode != null && i.barcode!.toUpperCase() == normalized) {
        match = i;
        break;
      }
      if (i.itemCode.toUpperCase() == normalized ||
          i.supplierCode.toUpperCase() == normalized) {
        match = i;
        break;
      }
    }

    if (match == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.noBarcodeMatch(code)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.rMd)),
        ),
      );
      return;
    }

    // Open the search bar if the item is hidden by the current filter
    if (_query.isNotEmpty) {
      setState(() {
        _query = '';
        _searchOpen = false;
      });
    }

    // Trigger scroll-and-flash. _Body listens to this notifier.
    _flashId.value = match.quotationItemId;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _flashId.value == match!.quotationItemId) {
        _flashId.value = null;
      }
    });
  }

  List<StockCheckItem> _sortAndFilter(List<StockCheckItem> raw) {
    final q = _query.trim().toLowerCase();
    // Preserve original database order — dynamic sorting causes click-target
    // positions to jump while the user is tapping, making cards register on
    // the wrong item.
    if (q.isEmpty) return List<StockCheckItem>.from(raw);
    return raw.where((i) {
      return i.productName.toLowerCase().contains(q) ||
          i.itemCode.toLowerCase().contains(q) ||
          i.supplierCode.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l            = context.l10n;
    final state        = ref.watch(stockCheckProvider(widget.quotationId));
    final transferState = ref.watch(transferActionProvider(widget.quotationId));
    final saveStatus   = ref.watch(saveStatusProvider(widget.quotationId));
    final notifier     = ref.read(stockCheckProvider(widget.quotationId).notifier);
    final rawItems     = state.valueOrNull ?? const <StockCheckItem>[];

    final visibleItems = _sortAndFilter(rawItems);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        await notifier.flushPendingSave();
        if (mounted) nav.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(l.stockCheckTitle),
                  const SizedBox(width: 8),
                  _DeliveryBadge(deliveryType: widget.deliveryType),
                ],
              ),
              Text(
                'Quotation #${widget.quotationId}',
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
              child: SizedBox(
                width: 96,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: saveStatus == SaveStatus.idle ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: saveStatus == SaveStatus.idle,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SaveStatusChip(
                        status: saveStatus,
                        onRetry: saveStatus == SaveStatus.failed
                            ? () => notifier.flushPendingSave()
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            if (rawItems.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                tooltip: l.tooltipScan,
                onPressed: () => _openScanner(rawItems),
              ),
            if (rawItems.isNotEmpty)
              IconButton(
                icon: Icon(
                  _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                  size: 22,
                ),
                tooltip: _searchOpen ? l.tooltipCloseSearch : l.tooltipSearchItems,
                onPressed: () => setState(() {
                  _searchOpen = !_searchOpen;
                  if (!_searchOpen) _query = '';
                }),
              ),
            if (state.hasValue && rawItems.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 22),
                tooltip: l.tooltipPdf,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PdfPreviewScreen(
                      quotationId: widget.quotationId,
                      quoteNo: widget.quoteNo,
                      salespersonName: widget.salespersonName,
                      customerName: widget.customerName,
                      deliveryType: widget.deliveryType,
                      items: rawItems,
                    ),
                  ),
                ),
              ),
            if (state.hasValue && rawItems.isNotEmpty)
              PopupMenuButton<String>(
                tooltip: l.tooltipMore,
                icon: const Icon(Icons.more_vert_rounded, size: 22),
                onSelected: (v) {
                  if (v == 'history') {
                    showStockCheckHistorySheet(
                      context,
                      quotationId: widget.quotationId,
                    );
                  } else if (v == 'cancel') {
                    _cancelTransfer();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 18),
                        const SizedBox(width: AppSpacing.s10),
                        Text(l.menuShowHistory),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined,
                            size: 18, color: AppConstants.dangerColor),
                        SizedBox(width: AppSpacing.s10),
                        Text('Cancel Transfer',
                            style:
                                TextStyle(color: AppConstants.dangerColor)),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(width: AppSpacing.s4),
          ],
        ),
        body: state.when(
          loading: () => const _LoadingBody(),
          error: (e, _) => _ErrorBody(error: e.toString()),
          data: (_) {
            if (rawItems.isEmpty) {
              return EmptyState(
                icon: Icons.inventory_2_outlined,
                iconColor: AppConstants.primaryColor,
                title: l.emptyNoItemsTitle,
                message: l.emptyNoItemsMsg,
              );
            }
            return _Body(
              quotationId: widget.quotationId,
              allItems: rawItems,
              visibleItems: visibleItems,
              searchOpen: _searchOpen,
              query: _query,
              onSearchChanged: (v) => setState(() => _query = v),
              flashId: _flashId,
            );
          },
        ),
        bottomNavigationBar: _BottomBar(
          quotationId: widget.quotationId,
          items: rawItems,
          isLoading: transferState.isLoading,
          allChecked: rawItems.isNotEmpty &&
              rawItems.every((i) => i.isChecked),
          missingReason: notifier.hasMissingShortageReason,
          itemsLoaded: state.hasValue,
        ),
      ),
    );
  }
}

// ── Loading ──────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: AppConstants.primaryColor,
      ),
    );
  }
}

// ── Error ────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String error;
  const _ErrorBody({required this.error});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline_rounded,
      iconColor: AppConstants.dangerColor,
      title: context.l10n.errorTitle,
      message: error,
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _Body extends ConsumerStatefulWidget {
  final int quotationId;
  final List<StockCheckItem> allItems;
  final List<StockCheckItem> visibleItems;
  final bool searchOpen;
  final String query;
  final ValueChanged<String> onSearchChanged;
  final ValueNotifier<int?> flashId;

  const _Body({
    required this.quotationId,
    required this.allItems,
    required this.visibleItems,
    required this.searchOpen,
    required this.query,
    required this.onSearchChanged,
    required this.flashId,
  });

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    widget.flashId.addListener(_onFlashIdChanged);
  }

  @override
  void didUpdateWidget(covariant _Body old) {
    super.didUpdateWidget(old);
    if (old.flashId != widget.flashId) {
      old.flashId.removeListener(_onFlashIdChanged);
      widget.flashId.addListener(_onFlashIdChanged);
    }
  }

  @override
  void dispose() {
    widget.flashId.removeListener(_onFlashIdChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onFlashIdChanged() {
    final id = widget.flashId.value;
    if (id == null) {
      setState(() {}); // clear highlight
      return;
    }
    // Wait one frame so the keys are attached after a possible re-filter.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {}); // pick up new highlight
      final key = _itemKeys[id];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          alignment: 0.15,
        );
      }
    });
  }

  GlobalKey _keyFor(int id) =>
      _itemKeys.putIfAbsent(id, () => GlobalKey(debugLabel: 'item-$id'));

  @override
  Widget build(BuildContext context) {
    final allItems = widget.allItems;
    final visibleItems = widget.visibleItems;
    final checkedCount =
        allItems.where((i) => i.isChecked).length;
    final availableCount =
        allItems.where((i) => i.status == CheckStatus.available).length;
    final partialCount =
        allItems.where((i) => i.status == CheckStatus.partial).length;
    final oosCount =
        allItems.where((i) => i.status == CheckStatus.outOfStock).length;
    final progress = checkedCount / allItems.length;
    final isDone = progress == 1.0;
    final highlightedId = widget.flashId.value;

    return Column(
      children: [
        // Optional search bar
        if (widget.searchOpen)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s16,
                AppSpacing.s12, AppSpacing.s16, 0),
            child: TextField(
              autofocus: true,
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                hintText: context.l10n.searchItemsHint,
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: widget.query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => widget.onSearchChanged(''),
                      )
                    : null,
              ),
            ),
          ),

        // Progress section (stays at top, not sliver-pinned)
        _ProgressSection(
          total: allItems.length,
          checkedCount: checkedCount,
          availableCount: availableCount,
          partialCount: partialCount,
          oosCount: oosCount,
          progress: progress,
          isDone: isDone,
          filterCount: widget.searchOpen ? visibleItems.length : null,
        ),

        // Table header + rows
        Expanded(
          child: visibleItems.isEmpty
              ? EmptyState(
                  icon: Icons.search_off_rounded,
                  iconColor: AppConstants.textMuted(context),
                  title: context.l10n.emptyNoMatchesTitle,
                  message: context.l10n.emptyNoMatchesMsg,
                )
              : LayoutBuilder(builder: (context, box) {
                  // Below ~680px the item cards switch to their stacked phone
                  // layout, so the aligned table header no longer matches —
                  // hide it there.
                  final narrow = box.maxWidth < 680;
                  return Column(
                  children: [
                    // Sticky column header
                    if (!narrow)
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppConstants.goldBorder(context)),
                            bottom: BorderSide(color: AppConstants.goldBorder(context), width: 1.5),
                          ),
                        ),
                        child: const StockTableHeader(),
                      ),
                    // Rows
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                        itemCount: visibleItems.length,
                        itemBuilder: (ctx, i) {
                          final item = visibleItems[i];
                          final originalIndex = allItems.indexOf(item) + 1;
                          return KeyedSubtree(
                            key: _keyFor(item.quotationItemId),
                            child: StockItemCard(
                              key: ValueKey(item.quotationItemId),
                              index: originalIndex,
                              item: item,
                              isEven: i.isEven,
                              isHighlighted:
                                  highlightedId == item.quotationItemId,
                              onChanged: (updated) => ref
                                  .read(stockCheckProvider(widget.quotationId)
                                      .notifier)
                                  .updateItem(updated),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  );
                }),
        ),
      ],
    );
  }
}

// ── Progress section ──────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final int total;
  final int checkedCount;
  final int availableCount;
  final int partialCount;
  final int oosCount;
  final double progress;
  final bool isDone;
  final int? filterCount;

  const _ProgressSection({
    required this.total,
    required this.checkedCount,
    required this.availableCount,
    required this.partialCount,
    required this.oosCount,
    required this.progress,
    required this.isDone,
    this.filterCount,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor =
        isDone ? AppConstants.successColor : AppConstants.primaryColor;

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s4),
      padding: const EdgeInsets.all(AppSpacing.s14),
      decoration: BoxDecoration(
        color: AppConstants.cardBg(context),
        borderRadius: BorderRadius.circular(AppSpacing.rLg),
        border: Border.all(
          color: isDone
              ? AppConstants.successColor.withValues(alpha: 0.3)
              : AppConstants.goldBorder(context),
          width: isDone ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDone ? context.l10n.allChecked : context.l10n.labelProgress,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDone
                            ? AppConstants.successColor
                            : AppConstants.textMuted(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      filterCount != null
                          ? context.l10n.showingFilter(filterCount!, total, checkedCount)
                          : context.l10n.itemsChecked(checkedCount, total),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppConstants.textFaint(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12, vertical: AppSpacing.s6),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.rPill),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: progressColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppConstants.softSurface(context),
                color: progressColor,
              ),
            ),
          ),
          if (checkedCount > 0) ...[
            const SizedBox(height: AppSpacing.s10),
            Wrap(
              spacing: AppSpacing.s6,
              runSpacing: AppSpacing.s4,
              children: [
                if (availableCount > 0)
                  _StatChip(
                    count: availableCount,
                    label: context.l10n.statusAvailable,
                    color: AppConstants.successColor,
                    icon: Icons.check_circle_rounded,
                  ),
                if (partialCount > 0)
                  _StatChip(
                    count: partialCount,
                    label: context.l10n.statusPartial,
                    color: AppConstants.warningColor,
                    icon: Icons.remove_circle_rounded,
                  ),
                if (oosCount > 0)
                  _StatChip(
                    count: oosCount,
                    label: context.l10n.statusOutOfStock,
                    color: AppConstants.dangerColor,
                    icon: Icons.cancel_rounded,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.rPill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: AppSpacing.s4),
          Text(
            '$count $label',
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

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends ConsumerWidget {
  final int quotationId;
  final List<StockCheckItem> items;
  final bool isLoading;
  final bool allChecked;
  final bool missingReason;
  final bool itemsLoaded;

  const _BottomBar({
    required this.quotationId,
    required this.items,
    required this.isLoading,
    required this.allChecked,
    required this.missingReason,
    required this.itemsLoaded,
  });

  bool get _hasIssue => items.any(
        (i) =>
            i.status == CheckStatus.partial ||
            i.status == CheckStatus.outOfStock,
      );

  bool get _nothingCheckedYet =>
      itemsLoaded && items.isNotEmpty && items.every((i) => !i.isChecked);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l          = context.l10n;
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final saveStatus = ref.watch(saveStatusProvider(quotationId));
    final saveFailed = saveStatus == SaveStatus.failed;
    final saveBusy   = saveStatus == SaveStatus.saving;
    final hasIssue   = _hasIssue;
    final buttonColor = hasIssue ? AppConstants.warningColor : AppConstants.infoColor;
    final buttonLabel = hasIssue ? l.btnSendReview : l.btnMarkTransferred;
    final buttonIcon  = hasIssue
        ? Icons.assignment_return_rounded
        : Icons.swap_horiz_rounded;

    // Block when saves are pending/failed — stale DB state would cause RPC errors
    final enabled = allChecked && !missingReason && !isLoading && !saveFailed && !saveBusy;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s16,
        AppSpacing.s12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppConstants.cardBg(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mark all available (only when nothing has been checked yet)
          if (_nothingCheckedYet) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _markAllAvailable(context, ref),
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: Text(l.markAllAvailableBtn(items.length)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.successColor,
                  side: BorderSide(
                    color:
                        AppConstants.successColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s10),
          ],

          // Status messages
          if (!allChecked && itemsLoaded) ...[
            _HintRow(
              icon: Icons.info_outline_rounded,
              text: l.hintCheckAll,
              color: AppConstants.textFaint(context),
            ),
            const SizedBox(height: AppSpacing.s10),
          ] else if (allChecked && missingReason) ...[
            _HintRow(
              icon: Icons.warning_amber_rounded,
              text: l.hintAddShortageReason,
              color: AppConstants.dangerColor,
            ),
            const SizedBox(height: AppSpacing.s10),
          ],

          if (allChecked && hasIssue && !missingReason) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s12,
                  AppSpacing.s8, AppSpacing.s12, AppSpacing.s8),
              margin: const EdgeInsets.only(bottom: AppSpacing.s10),
              decoration: BoxDecoration(
                color: AppConstants.warningColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.rMd),
                border: Border.all(
                    color: AppConstants.warningColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 15, color: AppConstants.warningColor),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      l.hintIssuesNotify,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppConstants.warningColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Save-failed warning — blocks submit until user retries
          if (saveFailed) ...[
            _HintRow(
              icon: Icons.cloud_off_rounded,
              text: 'Save failed — tap Retry above before submitting.',
              color: AppConstants.dangerColor,
            ),
            const SizedBox(height: AppSpacing.s10),
          ],

          // Selling entity — choose before transferring (Mark-as-Transferred path only)
          if (allChecked && !hasIssue && !missingReason) ...[
            _buildSellAsSelector(context, ref),
            const SizedBox(height: AppSpacing.s10),
          ],

          // Action button
          isLoading
              ? const SizedBox(
                  height: 52,
                  child: Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                )
              : FilledButton.icon(
                  onPressed: enabled
                      ? () => _onTap(context, ref, hasIssue)
                      : null,
                  icon: Icon(buttonIcon, size: 18),
                  label: Text(buttonLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: buttonColor,
                    disabledBackgroundColor: AppConstants.disabledBg(context),
                    disabledForegroundColor: AppConstants.disabledFg(context),
                  ),
                ),

          // Escape hatch — always available: mark transferred and do Al-Khazen by hand.
          if (!isLoading)
            TextButton.icon(
              onPressed: () => _handleManualTap(context, ref),
              icon: const Icon(Icons.handyman_outlined, size: 16),
              label: Text(context.l10n.handleManuallyBtn),
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.textFaint(context),
              ),
            ),
        ],
      ),
    );
  }

  /// Segmented selector: who sells — Hamasat (full flow) or Flower Center (transfer only).
  Widget _buildSellAsSelector(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(sellAsProvider(quotationId));
    Widget chip(String value, String label, IconData icon) {
      final active = selected == value;
      return Expanded(
        child: InkWell(
          onTap: () =>
              ref.read(sellAsProvider(quotationId).notifier).state = value,
          borderRadius: BorderRadius.circular(AppSpacing.rMd),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
            decoration: BoxDecoration(
              color: active
                  ? AppConstants.primaryColor.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.rMd),
              border: Border.all(
                color: active
                    ? AppConstants.primaryColor
                    : AppConstants.textFaint(context).withValues(alpha: 0.35),
                width: active ? 1.6 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 16,
                    color: active
                        ? AppConstants.primaryColor
                        : AppConstants.textFaint(context)),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active
                        ? AppConstants.primaryColor
                        : AppConstants.textFaint(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Text(
          context.l10n.sellAsLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppConstants.textFaint(context),
          ),
        ),
        const SizedBox(width: AppSpacing.s10),
        chip('hamasat', context.l10n.sellAsHamasat, Icons.local_florist_rounded),
        const SizedBox(width: AppSpacing.s8),
        chip('flowercenter', context.l10n.sellAsFlowerCenter, Icons.storefront_rounded),
      ],
    );
  }

  Future<void> _markAllAvailable(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final l2 = ctx.l10n;
            return AlertDialog(
              title: Text(l2.dialogMarkAllTitle),
              content: Text(l2.dialogMarkAllContent(items.length)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l2.btnCancel)),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppConstants.successColor),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l2.btnMarkAll),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!confirmed) return;
    await ref
        .read(stockCheckProvider(quotationId).notifier)
        .markAllAvailable();
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    bool hasIssue,
  ) async {
    final confirmed = await _confirm(context, hasIssue: hasIssue);
    if (!confirmed || !context.mounted) return;

    // Flush any pending saves first so the action sees latest data
    await ref
        .read(stockCheckProvider(quotationId).notifier)
        .flushPendingSave();
    if (!context.mounted) return;

    final notifier =
        ref.read(transferActionProvider(quotationId).notifier);

    if (hasIssue) {
      final ok = await notifier.sendForReview();
      if (!context.mounted) return;
      if (ok) {
        _snack(context, context.l10n.snackSentReview, AppConstants.warningColor);
        Navigator.of(context).pop();
      } else {
        _snack(context, 'Error: ${ref.read(transferActionProvider(quotationId)).error}',
            AppConstants.dangerColor);
      }
      return;
    }

    final sellAs = ref.read(sellAsProvider(quotationId));
    final result = await notifier.markTransferred(sellAs: sellAs);
    if (!context.mounted) return;
    await _handleMarkResult(context, ref, result);
  }

  void _snack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.rMd)),
    ));
  }

  Future<void> _handleMarkResult(
      BuildContext context, WidgetRef ref, MarkTransferResult result) async {
    final l = context.l10n;
    switch (result.outcome) {
      case MarkOutcome.success:
        _snack(context, l.snackTransferred, AppConstants.successColor);
        Navigator.of(context).pop();
        break;
      case MarkOutcome.manual:
        _snack(context, l.snackTransferredManual, AppConstants.successColor);
        Navigator.of(context).pop();
        break;
      case MarkOutcome.timeout:
        _snack(context, l.snackTransferQueued, AppConstants.infoColor);
        Navigator.of(context).pop();
        break;
      case MarkOutcome.noFixedPrice:
        await _showNoFixedPriceDialog(context, ref, result.detail ?? '');
        break;
      case MarkOutcome.error:
        _snack(context, 'Error: ${result.detail}', AppConstants.dangerColor);
        break;
    }
  }

  /// No-fixed-price dialog: fix in Al-Khazen and retry, or handle manually.
  Future<void> _showNoFixedPriceDialog(
      BuildContext context, WidgetRef ref, String items) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final l = ctx.l10n;
        return AlertDialog(
          title: Text(l.noFixedPriceTitle),
          content: Text(l.noFixedPriceContent(items)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: Text(l.btnCancel)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, 'manual'),
                child: Text(l.btnHandleManually)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, 'retry'),
                child: Text(l.btnRetry)),
          ],
        );
      },
    );
    if (choice == null || choice == 'cancel' || !context.mounted) return;
    final sellAs =
        choice == 'manual' ? 'manual' : ref.read(sellAsProvider(quotationId));
    final result = await ref
        .read(transferActionProvider(quotationId).notifier)
        .markTransferred(sellAs: sellAs);
    if (!context.mounted) return;
    await _handleMarkResult(context, ref, result);
  }

  /// "Handle manually" — mark transferred with no Al-Khazen job, skipping the
  /// usual all-items-checked requirement.
  Future<void> _handleManualTap(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final l = ctx.l10n;
            return AlertDialog(
              title: Text(l.manualTransferTitle),
              content: Text(l.manualTransferContent),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l.btnCancel)),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l.btnHandleManually)),
              ],
            );
          },
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final result = await ref
        .read(transferActionProvider(quotationId).notifier)
        .markTransferred(sellAs: 'manual');
    if (!context.mounted) return;
    await _handleMarkResult(context, ref, result);
  }

  Future<bool> _confirm(
    BuildContext context, {
    required bool hasIssue,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final l = ctx.l10n;
            return AlertDialog(
              title: Text(
                hasIssue ? l.dialogSendReviewTitle : l.dialogConfirmTransferTitle,
              ),
              content: Text(
                hasIssue ? l.dialogSendReviewContent : l.dialogConfirmTransferContent,
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l.btnCancel)),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: hasIssue
                        ? AppConstants.warningColor
                        : AppConstants.infoColor,
                  ),
                  child: Text(hasIssue ? l.btnSendReview : l.btnConfirm),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

class _HintRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _HintRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: AppSpacing.s6),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ),
      ],
    );
  }
}

// ── Delivery Badge ────────────────────────────────────────────────────────────

class _DeliveryBadge extends StatelessWidget {
  final DeliveryType deliveryType;
  const _DeliveryBadge({required this.deliveryType});

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
          Colors.grey.withValues(alpha: 0.12),
          Colors.grey.shade700,
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
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            deliveryType.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
