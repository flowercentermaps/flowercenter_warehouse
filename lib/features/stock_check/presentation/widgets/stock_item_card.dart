import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/check_status.dart';
import '../../domain/entities/stock_check_item.dart';
import '../providers/stock_check_provider.dart';
import 'status_toggle.dart';

class StockItemCard extends StatefulWidget {
  final int index;
  final StockCheckItem item;
  final ValueChanged<StockCheckItem> onChanged;

  const StockItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
  });

  @override
  State<StockItemCard> createState() => _StockItemCardState();
}

class _StockItemCardState extends State<StockItemCard> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _reasonCtrl;
  late final TextEditingController _suggCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl    = TextEditingController(text: widget.item.quantityAvailable?.toString() ?? '');
    _reasonCtrl = TextEditingController(text: widget.item.shortageReason    ?? '');
    _suggCtrl   = TextEditingController(text: widget.item.suggestion        ?? '');
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    _suggCtrl.dispose();
    super.dispose();
  }

  void _emit(StockCheckItem updated) => widget.onChanged(updated);

  void _onStatusChanged(CheckStatus newStatus) {
    // Clear fields that don't apply to the new status
    StockCheckItem updated;
    if (newStatus == CheckStatus.available) {
      updated = widget.item.copyWith(
        status: newStatus,
        clearQuantityAvailable: true,
        clearShortageReason:    true,
        clearSuggestion:        true,
      );
      _qtyCtrl.clear();
      _reasonCtrl.clear();
      _suggCtrl.clear();
    } else if (newStatus == CheckStatus.outOfStock) {
      updated = widget.item.copyWith(
        status: newStatus,
        clearQuantityAvailable: true,
        clearShortageReason:    true,
      );
      _qtyCtrl.clear();
      _reasonCtrl.clear();
    } else {
      updated = widget.item.copyWith(status: newStatus);
    }
    _emit(updated);
  }

  Color get _borderColor => switch (widget.item.status) {
        CheckStatus.available   => AppConstants.successColor.withValues(alpha: 0.5),
        CheckStatus.partial     => AppConstants.warningColor.withValues(alpha: 0.5),
        CheckStatus.outOfStock  => AppConstants.dangerColor.withValues(alpha: 0.5),
        CheckStatus.pending     => Colors.grey.withValues(alpha: 0.2),
      };

  @override
  Widget build(BuildContext context) {
    final item   = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Index badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TextButton(
                      //   onPressed: () {
                      //     item.printDetails();
                      //   },
                      //   child: const Icon(Icons.print),
                      // ),
                      if (item.itemCode.isNotEmpty)
                        Text(
                          item.itemCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                      Text(
                        item.productName.isNotEmpty ? item.productName : '—',
                        style: TextStyle(
                          fontWeight: item.itemCode.isNotEmpty
                              ? FontWeight.w400
                              : FontWeight.w700,
                          fontSize: item.itemCode.isNotEmpty ? 11.5 : 13.5,
                          color: item.itemCode.isNotEmpty
                              ? Colors.grey
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                // Qty needed pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Qty: ${_fmtQty(item.quantityNeeded)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Status toggle ─────────────────────────────────────────
            const Text('Status',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: StatusToggle(
                current: item.status,
                onChanged: _onStatusChanged,
              ),
            ),

            // ── Warehouse location ────────────────────────────────────
            const SizedBox(height: 12),
            _LocationDropdown(
              itemCode: item.itemCode,
              value: item.warehouseLocation,
              onChanged: (loc) => _emit(item.copyWith(warehouseLocation: loc)),
            ),

            // ── Partial-specific fields ───────────────────────────────
            if (item.status == CheckStatus.partial) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                      ],
                      onChanged: (v) => _emit(
                        item.copyWith(
                            quantityAvailable: double.tryParse(v)),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Qty Available',
                        prefixIcon: Icon(Icons.numbers_rounded, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _reasonCtrl,
                      onChanged: (v) =>
                          _emit(item.copyWith(shortageReason: v)),
                      decoration: const InputDecoration(
                        labelText: 'Shortage reason',
                        prefixIcon: Icon(Icons.info_outline_rounded, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // ── Partial suggestion ────────────────────────────────────
            if (item.status == CheckStatus.partial) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _suggCtrl,
                onChanged: (v) => _emit(item.copyWith(suggestion: v)),
                decoration: const InputDecoration(
                  labelText: 'Similar item suggestion (optional)',
                  prefixIcon: Icon(Icons.swap_horiz_rounded, size: 18),
                ),
              ),
            ],

            // ── Out-of-stock suggestion ───────────────────────────────
            if (item.status == CheckStatus.outOfStock) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _suggCtrl,
                onChanged: (v) => _emit(item.copyWith(suggestion: v)),
                decoration: const InputDecoration(
                  labelText: 'Similar item suggestion (optional)',
                  prefixIcon: Icon(Icons.swap_horiz_rounded, size: 18),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtQty(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ── Location dropdown ──────────────────────────────────────────────────────

class _LocationDropdown extends ConsumerWidget {
  final String itemCode;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _LocationDropdown({
    required this.itemCode,
    this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(warehouseLocationsProvider(itemCode));
    final stores = locationsAsync.valueOrNull ?? [];

    String fmtQty(double v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

    final storeNames = stores.map((s) => s.storeName).toList();

    return DropdownButtonFormField<String>(
      value: storeNames.contains(value) ? value : null,
      hint: const Text('Select warehouse location'),
      decoration: InputDecoration(
        labelText: 'Warehouse / Store',
        prefixIcon: const Icon(Icons.store_outlined, size: 18),
        suffixIcon: locationsAsync.isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      items: stores.map((s) => DropdownMenuItem(
            value: s.storeName,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.storeName, overflow: TextOverflow.ellipsis),
                if (s.quantity > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      fmtQty(s.quantity),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )).toList(),
      onChanged: stores.isEmpty ? null : onChanged,
    );
  }
}
