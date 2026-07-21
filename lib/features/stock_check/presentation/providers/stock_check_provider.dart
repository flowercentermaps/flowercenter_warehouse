import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/widgets/save_status_chip.dart';
import '../../data/datasources/stock_check_remote_datasource.dart';
import '../../data/repositories/stock_check_repository_impl.dart';
import '../../domain/entities/check_status.dart';
import '../../domain/entities/stock_check_item.dart';
import '../../domain/repositories/stock_check_repository.dart';

// ── Warehouse locations with quantities (per item) ─────────────────────────

class StoreStock {
  final String storeName;
  final double quantity;
  const StoreStock({required this.storeName, required this.quantity});
}

/// Escapes regex metacharacters so a supplier code can be matched literally.
String _escapeRegex(String s) =>
    s.replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (m) => '\\${m[0]}');

/// Fetches ALL store names and merges with per-item quantities.
/// Every store appears in the dropdown regardless of whether it stocks the item;
/// stores without a matching row show quantity 0.
final warehouseLocationsProvider =
    FutureProvider.autoDispose.family<List<StoreStock>, String>((ref, itemCode) async {
  final client = Supabase.instance.client;

  // Fire both queries concurrently.
  final futures = await Future.wait([
    // 1. All distinct store names (always needed)
    client.from('stock_quantities').select('store_name').order('store_name'),
    // 2. Per-item quantities (only meaningful when itemCode is known).
    // Matched via an anchored, whitespace-tolerant regex rather than exact
    // equality — a stray leading/trailing space in Al-Khazen's own source
    // data (KT_ART.SupplCodeId) would otherwise make that store's row
    // silently vanish from this lookup (seen in production: article 601073
    // reverted to " MA1020-26" after a stock change re-synced it).
    if (itemCode.isNotEmpty)
      client
          .from('stock_quantities')
          .select('store_name, quantity')
          .filter('supplier_code', 'imatch', '^\\s*${_escapeRegex(itemCode.trim())}\\s*\$')
    else
      Future.value(<dynamic>[]),
  ]);

  // Build the full store set.
  final allStores = <String>{};
  for (final r in futures[0] as List) {
    final name = (r['store_name'] ?? '').toString().trim();
    if (name.isNotEmpty) allStores.add(name);
  }

  // Aggregate item-specific quantities.
  final totals = <String, double>{};
  for (final r in futures[1] as List) {
    final name = (r['store_name'] ?? '').toString().trim();
    if (name.isEmpty) continue;
    totals[name] = (totals[name] ?? 0) +
        ((r['quantity'] as num?) ?? 0).toDouble();
  }

  // Every store appears; those without stock for this item get 0.
  return (allStores
        .map((n) => StoreStock(storeName: n, quantity: totals[n] ?? 0))
        .toList()
      ..sort((a, b) => a.storeName.compareTo(b.storeName)));
});

// ── Dependency providers ───────────────────────────────────────────────────

final stockCheckRepositoryProvider = Provider<StockCheckRepository>((ref) {
  final ds = StockCheckRemoteDataSource(Supabase.instance.client);
  return StockCheckRepositoryImpl(ds);
});

// ── Save status (one notifier per quotationId) ─────────────────────────────

class SaveStatusNotifier extends FamilyNotifier<SaveStatus, int> {
  Timer? _autoFade;

  @override
  SaveStatus build(int arg) {
    ref.onDispose(() => _autoFade?.cancel());
    return SaveStatus.idle;
  }

  void setSaving() {
    _autoFade?.cancel();
    state = SaveStatus.saving;
  }

  void setSaved() {
    state = SaveStatus.saved;
    _autoFade?.cancel();
    _autoFade = Timer(const Duration(seconds: 2), () {
      if (state == SaveStatus.saved) state = SaveStatus.idle;
    });
  }

  void setFailed() {
    _autoFade?.cancel();
    state = SaveStatus.failed;
  }

  void setIdle() {
    _autoFade?.cancel();
    state = SaveStatus.idle;
  }
}

final saveStatusProvider =
    NotifierProviderFamily<SaveStatusNotifier, SaveStatus, int>(
  SaveStatusNotifier.new,
);

// ── Family provider (one per quotationId) ─────────────────────────────────

class StockCheckNotifier
    extends FamilyAsyncNotifier<List<StockCheckItem>, int> {
  Timer? _saveTimer;
  // Keyed by quotationItemId so multiple items updated within the debounce
  // window are all saved (not just the last one).
  final Map<int, StockCheckItem> _pendingItems = {};

  @override
  Future<List<StockCheckItem>> build(int arg) async {
    ref.onDispose(() => _saveTimer?.cancel());
    final repo = ref.read(stockCheckRepositoryProvider);
    return repo.loadItems(arg);
  }

  /// Update a single item's status and trigger a debounced save.
  void updateItem(StockCheckItem updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    final idx = current.indexWhere(
        (i) => i.quotationItemId == updated.quotationItemId);
    if (idx < 0) return;
    final newList = [...current];
    newList[idx] = updated;
    state = AsyncData(newList);
    _scheduleSave(updated);
  }

  void _scheduleSave(StockCheckItem item) {
    _saveTimer?.cancel();
    _pendingItems[item.quotationItemId] = item;
    ref.read(saveStatusProvider(arg).notifier).setSaving();
    _saveTimer = Timer(const Duration(milliseconds: 600), _flushPending);
  }

  /// True when a save failed because the quotation item no longer exists —
  /// the quote was edited in the CRM (items removed/replaced) while this
  /// screen was open, so our whole item list is stale and must be reloaded.
  static bool _isStaleItemError(Object e) =>
      e is PostgrestException &&
      (e.code == '23503' ||
          e.message.contains('quotation_stock_checks_quotation_item_id_fkey'));

  /// Drop stale state and refetch the current items from the server.
  void _reloadStaleItems() {
    _pendingItems.clear();
    ref.read(saveStatusProvider(arg).notifier).setIdle();
    ref.invalidateSelf();
  }

  Future<void> _flushPending() async {
    if (_pendingItems.isEmpty) return;
    final toSave = Map<int, StockCheckItem>.from(_pendingItems);
    _pendingItems.clear();
    try {
      final repo = ref.read(stockCheckRepositoryProvider);
      for (final item in toSave.values) {
        await repo.saveCheck(quotationId: arg, item: item);
        // Sync the (possibly new) checkRowId back into state so subsequent
        // copyWith calls inherit it and don't trigger duplicate INSERTs.
        // Also handles the fallback-INSERT case where an old stale checkRowId
        // (from rows cleared by "Re-approve for Transfer") gets replaced.
        final current = state.valueOrNull;
        if (current != null && item.checkRowId != null) {
          final idx = current.indexWhere(
              (i) => i.quotationItemId == item.quotationItemId);
          if (idx >= 0 && current[idx].checkRowId != item.checkRowId) {
            final updated = [...current];
            updated[idx] = current[idx].copyWith(checkRowId: item.checkRowId);
            state = AsyncData(updated);
          }
        }
      }
      ref.read(saveStatusProvider(arg).notifier).setSaved();
    } catch (e) {
      if (_isStaleItemError(e)) {
        // Quote was edited in the CRM — retrying the same rows can never
        // succeed. Reload the fresh item list instead.
        _reloadStaleItems();
        return;
      }
      // Restore so retry has something to save.
      _pendingItems.addAll(toSave);
      ref.read(saveStatusProvider(arg).notifier).setFailed();
    }
  }

  /// Cancel the debounce timer and flush any pending saves immediately.
  /// Returns when all pending saves (if any) have completed.
  Future<void> flushPendingSave() async {
    if (_pendingItems.isEmpty) return;
    _saveTimer?.cancel();
    await _flushPending();
  }

  /// Mark every item as Available, with quantity = quantityNeeded.
  /// Used by the "Mark all available" shortcut button.
  Future<void> markAllAvailable() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final repo = ref.read(stockCheckRepositoryProvider);
    final newList = <StockCheckItem>[];
    ref.read(saveStatusProvider(arg).notifier).setSaving();
    for (final item in current) {
      final updated = item.copyWith(
        status: CheckStatus.available,
        clearShortageReason: true,
        clearSuggestion: true,
        clearQuantityAvailable: true,
      );
      newList.add(updated);
    }
    state = AsyncData(newList);
    try {
      for (final item in newList) {
        await repo.saveCheck(quotationId: arg, item: item);
      }
      ref.read(saveStatusProvider(arg).notifier).setSaved();
    } catch (e) {
      if (_isStaleItemError(e)) {
        _reloadStaleItems();
        return;
      }
      ref.read(saveStatusProvider(arg).notifier).setFailed();
    }
  }

  bool get allChecked =>
      (state.valueOrNull ?? []).every((i) => i.isChecked);

  /// Shortage reason validation removed — always returns false.
  bool get hasMissingShortageReason => false;
}

final stockCheckProvider =
    AsyncNotifierProviderFamily<StockCheckNotifier, List<StockCheckItem>, int>(
  StockCheckNotifier.new,
);
