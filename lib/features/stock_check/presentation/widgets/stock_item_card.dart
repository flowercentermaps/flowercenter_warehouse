import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/product_thumbnail.dart';
import '../../domain/entities/check_status.dart';
import '../../domain/entities/stock_check_item.dart';
import '../../domain/entities/store_allocation.dart';
import '../providers/stock_check_provider.dart';
import 'shortage_history_sheet.dart';

// ── Shared column widths ──────────────────────────────────────────────────────
class _Col {
  static const double statusBar = 5;
  static const double index     = 36;
  static const double image     = 36;
  static const double item      = 190;
  static const double needed    = 52;
  static const double store     = 260;
  static const double avail     = 64;  // available qty in that store
  static const double qty       = 76;  // qty to send
  static const double del       = 30;
  static const double status    = 144;
}

// ── Table header ──────────────────────────────────────────────────────────────

class StockTableHeader extends StatelessWidget {
  const StockTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: AppConstants.primaryColor.withValues(alpha: 0.8),
      letterSpacing: 0.8,
    );

    return Container(
      color: isDark ? const Color(0xFF1C1600) : const Color(0xFFFFF8E7),
      child: Row(
        children: [
          const SizedBox(width: _Col.statusBar),
          _vd(context),
          _hcell(_Col.index,  Text('#', style: label, textAlign: TextAlign.center)),
          _vd(context),
          SizedBox(width: _Col.image + AppSpacing.s8 * 2),
          _hcell(_Col.item,   Text(context.l10n.colItem, style: label)),
          _vd(context),
          _hcell(_Col.needed, Text(context.l10n.colQty, style: label, textAlign: TextAlign.center)),
          _vd(context),
          SizedBox(
            width: _Col.store,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10, vertical: AppSpacing.s6),
              child: Text(context.l10n.colStore, style: label),
            ),
          ),
          _vd(context),
          _hcell(_Col.avail,  Text(context.l10n.colAvail, style: label, textAlign: TextAlign.center)),
          _vd(context),
          _hcell(_Col.qty,    Text(context.l10n.colSendQty, style: label, textAlign: TextAlign.center)),
          _vd(context),
          SizedBox(width: _Col.del),
          _vd(context),
          _hcell(_Col.status, Text(context.l10n.colStatus, style: label, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  static Widget _hcell(double w, Widget child) => SizedBox(
        width: w,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s6),
          child: child,
        ),
      );

  static Widget _vd(BuildContext ctx) => Container(
        width: 1,
        height: 30,
        color: AppConstants.goldBorder(ctx),
      );
}

// ── Table row ─────────────────────────────────────────────────────────────────

class StockItemCard extends ConsumerStatefulWidget {
  final int index;
  final StockCheckItem item;
  final ValueChanged<StockCheckItem> onChanged;
  final bool isHighlighted;
  final bool isEven;

  const StockItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    this.isHighlighted = false,
    this.isEven = false,
  });

  @override
  ConsumerState<StockItemCard> createState() => _StockItemCardState();
}

class _StockItemCardState extends ConsumerState<StockItemCard> {
  void _emit(StockCheckItem u) => widget.onChanged(u);

  void _onStatusChanged(CheckStatus s) {
    late StockCheckItem u;
    if (s == CheckStatus.available) {
      u = widget.item.copyWith(
        status: s,
        // Trees marked available with no store: record full qty as available
        quantityAvailable: widget.item.isTree && widget.item.storeAllocations.isEmpty
            ? widget.item.quantityNeeded
            : null,
        clearQuantityAvailable: !widget.item.isTree || widget.item.storeAllocations.isNotEmpty,
        clearShortageReason: true,
        clearSuggestion: true,
      );
    } else if (s == CheckStatus.outOfStock) {
      u = widget.item.copyWith(
          status: s, clearQuantityAvailable: true,
          clearShortageReason: true, clearStoreAllocations: true);
    } else {
      u = widget.item.copyWith(status: s);
    }
    _emit(u);
  }

  Color get _statusColor => switch (widget.item.status) {
        CheckStatus.available  => AppConstants.successColor,
        CheckStatus.partial    => AppConstants.warningColor,
        CheckStatus.outOfStock => AppConstants.dangerColor,
        CheckStatus.pending    => Colors.transparent,
      };

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = item.status == CheckStatus.pending;

    final rowBg = widget.isHighlighted
        ? AppConstants.primaryColor.withValues(alpha: 0.07)
        : widget.isEven
            ? (isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5))
            : (isDark ? const Color(0xFF1C1C1C) : Colors.white);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showShortageHistorySheet(context, item: item);
      },
      // Responsive: the aligned table row needs ~680px to breathe; below
      // that (phones) each item becomes a stacked card instead of a row
      // squeezing 8 fixed-width columns into a 400px screen.
      child: LayoutBuilder(builder: (context, box) {
        final narrow = box.maxWidth < 680;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: rowBg,
            border: Border(
              // In narrow mode the status strip becomes a left border —
              // the wide layout draws its own strip as the first cell.
              left: narrow
                  ? BorderSide(
                      color: isPending ? Colors.transparent : _statusColor,
                      width: 4)
                  : BorderSide.none,
              bottom: BorderSide(
                color: AppConstants.goldBorder(context),
                width: 2,
              ),
            ),
          ),
          child: narrow ? _narrowCard(context) : _wideRow(context, isPending),
        );
      }),
    );
  }

  /// Item identity block (codes + name) — shared by both layouts.
  Widget _codesAndName(BuildContext context) {
    final item = widget.item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if ((item.articleCodeId ?? '').isNotEmpty)
          _CopyableCode(
            text: item.articleCodeId!,
            label: 'ART',
            bold: true,
          ),
        if (item.itemCode.isNotEmpty)
          Row(
            children: [
              Flexible(child: _CopyableCode(text: item.itemCode, label: 'SKU')),
              if (item.isTree) ...[
                const SizedBox(width: 3),
                const Text('🌳', style: TextStyle(fontSize: 10)),
              ],
            ],
          ),
        if (item.supplierCode.isNotEmpty && item.supplierCode != item.itemCode)
          _CopyableCode(text: item.supplierCode, label: 'SUP'),
        if ((item.barcode ?? '').isNotEmpty)
          _CopyableCode(
            text: item.barcode!,
            label: '⬛',
            monospace: true,
          ),
        if (item.productName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(item.productName,
                style: TextStyle(
                    fontSize: 9.5, color: AppConstants.textFaint(context)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }

  /// Allocation editor (or OOS placeholder) — shared by both layouts.
  Widget _allocationsOrOos(BuildContext context, {required bool compact}) {
    final item = widget.item;
    if (item.status == CheckStatus.outOfStock) {
      return compact
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
              child: Text(context.l10n.outOfStockPlaceholder,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppConstants.dangerColor.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic)),
            )
          : _oosRow(context, context.l10n);
    }
    return _StoreAllocationsWidget(
      compact: compact,
      itemCode:
          item.supplierCode.isNotEmpty ? item.supplierCode : item.itemCode,
      allocations: item.storeAllocations,
      needed: item.quantityNeeded,
      isTree: item.isTree,
      currentStatus: item.status,
      onChanged: (newAllocs) {
        final total = newAllocs.fold(0.0, (s, a) => s + a.qty);
        CheckStatus auto;
        if (total >= item.quantityNeeded && total > 0) {
          auto = CheckStatus.available;
        } else if (total > 0) {
          auto = CheckStatus.partial;
        } else {
          // Trees: keep current status when store is cleared
          // (they can be available with no location)
          auto = item.isTree ? item.status : CheckStatus.pending;
        }
        _emit(item.copyWith(
          storeAllocations: newAllocs,
          status: auto,
          quantityAvailable:
              total > 0 ? total : (item.isTree ? item.quantityNeeded : null),
          clearQuantityAvailable: total == 0 && !item.isTree,
          clearShortageReason: auto == CheckStatus.available,
          clearSuggestion: auto == CheckStatus.available,
        ));
      },
    );
  }

  /// Phone layout: header row (badge, image, codes, needed qty), then the
  /// store allocations full-width, then the status chips.
  Widget _narrowCard(BuildContext context) {
    final item = widget.item;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s10, AppSpacing.s8, AppSpacing.s10, AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IndexBadge(index: widget.index, status: item.status),
              const SizedBox(width: AppSpacing.s8),
              ProductThumbnail(
                imageUrl: item.imageUrl,
                size: 44,
                heroTag: 'stock-item-${item.quotationItemId}',
                captionForFullscreen: item.itemCode,
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(child: _codesAndName(context)),
              const SizedBox(width: AppSpacing.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.rPill),
                ),
                child: Text('×${_fmt(item.quantityNeeded)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppConstants.primaryColor)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s6),
          _allocationsOrOos(context, compact: true),
          const SizedBox(height: AppSpacing.s4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _StatusChips(
              current: item.status,
              onChanged: _onStatusChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// Desktop/tablet layout: the original aligned table row.
  Widget _wideRow(BuildContext context, bool isPending) {
    final item = widget.item;
    return IntrinsicHeight(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left status bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: _Col.statusBar,
                color: isPending ? Colors.transparent : _statusColor,
              ),
              _VDiv(context),

              // #
              SizedBox(
                width: _Col.index,
                child: Center(child: _IndexBadge(index: widget.index, status: item.status)),
              ),
              _VDiv(context),

              // Image
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s8),
                child: Center(
                  child: ProductThumbnail(
                    imageUrl: item.imageUrl,
                    size: _Col.image,
                    heroTag: 'stock-item-${item.quotationItemId}',
                    captionForFullscreen: item.itemCode,
                  ),
                ),
              ),

              // Code + Name
              SizedBox(
                width: _Col.item,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s8, vertical: AppSpacing.s6),
                  child: _codesAndName(context),
                ),
              ),
              _VDiv(context),

              // Qty needed
              SizedBox(
                width: _Col.needed,
                child: Center(
                  child: Text(_fmt(item.quantityNeeded),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppConstants.primaryColor)),
                ),
              ),
              _VDiv(context),

              // Store allocations — must be Expanded so it gets bounded width
              Expanded(
                child: _allocationsOrOos(context, compact: false),
              ),

              _VDiv(context),

              // Status chips
              SizedBox(
                width: _Col.status,
                child: Center(
                  child: _StatusChips(
                    current: item.status,
                    onChanged: _onStatusChanged,
                  ),
                ),
              ),
            ],
          ),
          ),
        );
  }

  /// Placeholder row cells for out-of-stock items (store | avail | qty | del)
  Widget _oosRow(BuildContext context, AppLocalizations l) => Row(
        children: [
          Expanded(
            child: Center(
              child: Text(l.outOfStockPlaceholder,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppConstants.dangerColor.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic)),
            ),
          ),
          _VDiv(context),
          SizedBox(width: _Col.avail),
          _VDiv(context),
          SizedBox(width: _Col.qty),
          _VDiv(context),
          SizedBox(width: _Col.del),
        ],
      );

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ── Vertical divider ──────────────────────────────────────────────────────────

class _VDiv extends StatelessWidget {
  final BuildContext ctx;
  const _VDiv(this.ctx);
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        color: AppConstants.goldBorder(ctx).withValues(alpha: 0.6),
      );
}

// ── Status chips ──────────────────────────────────────────────────────────────

class _StatusChips extends StatelessWidget {
  final CheckStatus current;
  final ValueChanged<CheckStatus> onChanged;
  const _StatusChips({required this.current, required this.onChanged});

  static const _all = [
    CheckStatus.available,
    CheckStatus.partial,
    CheckStatus.outOfStock,
  ];

  Color _color(CheckStatus s) => switch (s) {
        CheckStatus.available  => AppConstants.successColor,
        CheckStatus.partial    => AppConstants.warningColor,
        CheckStatus.outOfStock => AppConstants.dangerColor,
        CheckStatus.pending    => Colors.grey,
      };

  IconData _icon(CheckStatus s) => switch (s) {
        CheckStatus.available  => Icons.check_circle_rounded,
        CheckStatus.partial    => Icons.remove_circle_rounded,
        CheckStatus.outOfStock => Icons.cancel_rounded,
        CheckStatus.pending    => Icons.radio_button_unchecked,
      };

  String _label(CheckStatus s, AppLocalizations l) => s.localizedShort(l);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: _all.map((s) {
        final sel = current == s;
        final color = _color(s);
        final fg = sel ? color : AppConstants.textFaint(context);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: GestureDetector(
            onTap: () {
              if (!sel) { HapticFeedback.selectionClick(); onChanged(s); }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: sel
                    ? color.withValues(alpha: 0.15)
                    : AppConstants.softSurface(context),
                borderRadius: BorderRadius.circular(AppSpacing.rSm),
                border: Border.all(
                  color: sel
                      ? color.withValues(alpha: 0.7)
                      : AppConstants.softBorder(context),
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon(s), size: 18, color: fg),
                  const SizedBox(height: 2),
                  Text(_label(s, l),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                          color: fg)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Index badge ───────────────────────────────────────────────────────────────

class _IndexBadge extends StatelessWidget {
  final int index;
  final CheckStatus status;
  const _IndexBadge({required this.index, required this.status});

  Color _color(BuildContext c) => switch (status) {
        CheckStatus.available  => AppConstants.successColor,
        CheckStatus.partial    => AppConstants.warningColor,
        CheckStatus.outOfStock => AppConstants.dangerColor,
        CheckStatus.pending    => AppConstants.primaryColor,
      };

  IconData? _icon() => switch (status) {
        CheckStatus.available  => Icons.check_rounded,
        CheckStatus.outOfStock => Icons.close_rounded,
        _                      => null,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final icon = _icon();
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.rSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 14, color: color)
            : Text('$index',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color)),
      ),
    );
  }
}

// ── Store allocations widget ──────────────────────────────────────────────────
// Renders inside the table row; columns align with header:
//   [Expanded: store dropdown] | [avail] | [qty] | [del]

class _StoreAllocationsWidget extends ConsumerStatefulWidget {
  final String itemCode;
  final List<StoreAllocation> allocations;
  final double needed;
  final bool isTree;
  final CheckStatus currentStatus;
  final void Function(List<StoreAllocation>) onChanged;
  /// Phone layout: the store dropdown flexes to fill the row instead of the
  /// fixed table-column width, and the qty cells shrink.
  final bool compact;

  const _StoreAllocationsWidget({
    required this.itemCode,
    required this.allocations,
    required this.needed,
    required this.isTree,
    required this.currentStatus,
    required this.onChanged,
    this.compact = false,
  });

  @override
  ConsumerState<_StoreAllocationsWidget> createState() =>
      _StoreAllocationsState();
}

class _StoreAllocationsState
    extends ConsumerState<_StoreAllocationsWidget> {
  late List<_AllocRow> _rows;

  @override
  void initState() {
    super.initState();
    _syncRows(widget.allocations);
  }

  @override
  void didUpdateWidget(_StoreAllocationsWidget old) {
    super.didUpdateWidget(old);
    final oldKeys = old.allocations.map((a) => '${a.storeName}:${a.qty}').toSet();
    final newKeys = widget.allocations.map((a) => '${a.storeName}:${a.qty}').toSet();
    if (oldKeys.length != newKeys.length || !oldKeys.containsAll(newKeys)) {
      for (final r in _rows) r.ctrl.dispose();
      _syncRows(widget.allocations);
    }
  }

  void _syncRows(List<StoreAllocation> allocs) {
    _rows = allocs.map((a) => _AllocRow(
          storeName: a.storeName,
          ctrl: TextEditingController(text: a.qty > 0 ? _fmt(a.qty) : ''),
        )).toList();
    if (_rows.isEmpty) _rows.add(_AllocRow(storeName: '', ctrl: TextEditingController()));
  }

  @override
  void dispose() {
    for (final r in _rows) r.ctrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  void _notify() {
    widget.onChanged(_rows
        .where((r) => r.storeName.isNotEmpty)
        .map((r) => StoreAllocation(
              storeName: r.storeName,
              qty: double.tryParse(r.ctrl.text) ?? 0,
            ))
        .toList());
  }

  void _removeRow(int i) {
    if (_rows.length == 1) {
      setState(() { _rows[0].storeName = ''; _rows[0].ctrl.clear(); });
    } else {
      _rows[i].ctrl.dispose();
      setState(() => _rows.removeAt(i));
    }
    _notify();
  }

  /// Store cell wrapper: fixed table-column width on wide layouts, flexes to
  /// fill the remaining row width in compact (phone) mode.
  Widget _storeCell({required Widget child}) => widget.compact
      ? Expanded(child: child)
      : SizedBox(width: _Col.store, child: child);

  @override
  Widget build(BuildContext context) {
    final locAsync = ref.watch(warehouseLocationsProvider(widget.itemCode));
    final stores = locAsync.valueOrNull ?? [];

    final total = _rows.fold(0.0, (s, r) => s + (double.tryParse(r.ctrl.text) ?? 0));
    final isComplete = total >= widget.needed && total > 0;
    final isOver = total > widget.needed && widget.needed > 0;

    // Each allocation row spans: [Expanded store] | [avail] | [qty] | [del]
    // We keep the vertical dividers so they align with the header columns.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _rows.length; i++) ...[
          if (i > 0)
            Divider(height: 1, color: AppConstants.goldBorder(context).withValues(alpha: 0.4)),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Store dropdown — fixed column on wide, flexes on phone
                _storeCell(
                  child: Center(
                    child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
                    child: DropdownButtonFormField<String>(
                      value: stores.any((s) => s.storeName == _rows[i].storeName)
                          ? _rows[i].storeName
                          : null,
                      hint: Text(context.l10n.storeSelectHint,
                          style: TextStyle(
                              fontSize: 11,
                              color: AppConstants.textFaint(context))),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        isDense: true,
                      ),
                      items: stores
                          .map((s) => DropdownMenuItem(
                                value: s.storeName,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(s.storeName,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12)),
                                    ),
                                    if (s.quantity > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppConstants.primaryColor,
                                          borderRadius: BorderRadius.circular(
                                              AppSpacing.rPill),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppConstants.primaryColor
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Text(_fmt(s.quantity),
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: 0.3)),
                                      ),
                                    ],
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: locAsync.isLoading
                          ? null
                          : (v) {
                              setState(() => _rows[i].storeName = v ?? '');
                              if (v != null && _rows[i].ctrl.text.isEmpty) {
                                final sq = stores.firstWhere(
                                  (s) => s.storeName == v,
                                  orElse: () =>
                                      StoreStock(storeName: '', quantity: 0),
                                );
                                if (sq.quantity > 0) {
                                  _rows[i].ctrl.text = _fmt(
                                      sq.quantity > widget.needed
                                          ? widget.needed
                                          : sq.quantity);
                                }
                              }
                              _notify();
                            },
                    ),
                  ),
                  ),
                ),

                _VDiv(context),

                // Available qty in this store
                SizedBox(
                  width: widget.compact ? 46 : _Col.avail,
                  child: Center(
                    child: _availText(context, stores, _rows[i].storeName),
                  ),
                ),

                _VDiv(context),

                // Qty to send
                SizedBox(
                  width: widget.compact ? 62 : _Col.qty,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s4, vertical: AppSpacing.s4),
                    child: TextField(
                      controller: _rows[i].ctrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: '0',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 10),
                        isDense: false,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) { setState(() {}); _notify(); },
                    ),
                  ),
                ),

                _VDiv(context),

                // Delete row
                SizedBox(
                  width: widget.compact ? 26 : _Col.del,
                  child: Center(
                    child: IconButton(
                      icon: Icon(Icons.remove_circle_outline_rounded,
                          size: 15, color: AppConstants.dangerColor),
                      onPressed: () => _removeRow(i),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Add store + tally footer
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s10, vertical: AppSpacing.s4),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _rows.add(
                    _AllocRow(storeName: '', ctrl: TextEditingController()))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded,
                        size: 12, color: AppConstants.primaryColor),
                    const SizedBox(width: 2),
                    Text(context.l10n.storeAdd,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryColor)),
                  ],
                ),
              ),
              // Trees: show "no location" label when available with no store
              if (widget.isTree &&
                  total == 0 &&
                  widget.currentStatus == CheckStatus.available) ...[
                const SizedBox(width: AppSpacing.s8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppConstants.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.rPill),
                    border: Border.all(
                        color: AppConstants.successColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'No location',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.successColor,
                    ),
                  ),
                ),
              ],
              if (total > 0) ...[
                const SizedBox(width: AppSpacing.s10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isOver
                        ? AppConstants.infoColor.withValues(alpha: 0.12)
                        : isComplete
                            ? AppConstants.successColor.withValues(alpha: 0.12)
                            : AppConstants.warningColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.rPill),
                    border: Border.all(
                      color: isOver
                          ? AppConstants.infoColor.withValues(alpha: 0.4)
                          : isComplete
                              ? AppConstants.successColor.withValues(alpha: 0.4)
                              : AppConstants.warningColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '${_fmt(total)} / ${_fmt(widget.needed)}${isComplete ? ' ✓' : ''}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isOver
                          ? AppConstants.infoColor
                          : isComplete
                              ? AppConstants.successColor
                              : AppConstants.warningColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _availText(BuildContext ctx, List<StoreStock> stores, String storeName) {
    if (storeName.isEmpty) {
      return Text('—',
          style: TextStyle(
              fontSize: 12, color: AppConstants.textFaint(ctx)));
    }
    final sq = stores.firstWhere(
      (s) => s.storeName == storeName,
      orElse: () => StoreStock(storeName: '', quantity: 0),
    );
    final qty = sq.quantity;
    final enough = qty >= widget.needed;
    final color = qty == 0
        ? AppConstants.dangerColor
        : enough
            ? AppConstants.successColor
            : AppConstants.warningColor;
    return Text(
      qty == 0 ? '0' : _fmt(qty),
      textAlign: TextAlign.center,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: color),
    );
  }
}

class _AllocRow {
  String storeName;
  final TextEditingController ctrl;
  _AllocRow({required this.storeName, required this.ctrl});
}

// ── Copyable code chip ────────────────────────────────────────────────────────

class _CopyableCode extends StatefulWidget {
  final String text;
  final String label;
  final bool bold;
  final bool monospace;

  const _CopyableCode({
    required this.text,
    required this.label,
    this.bold = false,
    this.monospace = false,
  });

  @override
  State<_CopyableCode> createState() => _CopyableCodeState();
}

class _CopyableCodeState extends State<_CopyableCode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    if (_copied) return;
    await Clipboard.setData(ClipboardData(text: widget.text));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    _ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    await _ctrl.reverse();
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppConstants.textMuted(context);

    return GestureDetector(
      onTap: _copy,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Normal code row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label tag
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: muted,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 3),
                // Code value
                Flexible(
                  child: Text(
                    widget.text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: widget.bold ? 11.5 : 10.5,
                      fontWeight: widget.bold
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontFamily: widget.monospace ? 'monospace' : null,
                      color: widget.bold
                          ? AppConstants.primaryColor
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      letterSpacing: widget.monospace ? 0.5 : 0,
                    ),
                  ),
                ),
              ],
            ),
            // "✓ Copied" overlay — fades in/out above the row
            Positioned(
              left: 0,
              top: -18,
              child: FadeTransition(
                opacity: _opacity,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppConstants.successColor,
                    borderRadius: BorderRadius.circular(AppSpacing.rPill),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.successColor.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    '✓ Copied',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
