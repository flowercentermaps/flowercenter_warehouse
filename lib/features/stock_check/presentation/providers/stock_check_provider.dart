import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/stock_check_remote_datasource.dart';
import '../../data/repositories/stock_check_repository_impl.dart';
import '../../domain/entities/stock_check_item.dart';
import '../../domain/repositories/stock_check_repository.dart';

// ── Warehouse locations with quantities (per item) ─────────────────────────

class StoreStock {
  final String storeName;
  final double quantity;
  const StoreStock({required this.storeName, required this.quantity});
}

/// Fetches store names + quantities for a given item_code (maps to supplier_code in stock_quantities).
/// When item_code has no matching rows, returns all distinct store names from the table.
final warehouseLocationsProvider =
    FutureProvider.family<List<StoreStock>, String>((ref, itemCode) async {
  final client = Supabase.instance.client;
  if (itemCode.isNotEmpty) {
    final res = await client
        .from('stock_quantities')
        .select('store_name, quantity')
        .eq('supplier_code', itemCode)
        .order('store_name');
    // Aggregate duplicate rows by summing quantity per store
    final totals = <String, double>{};
    for (final r in res as List) {
      final name = (r['store_name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      totals[name] = (totals[name] ?? 0) +
          ((r['quantity'] as num?) ?? 0).toDouble();
    }
    if (totals.isNotEmpty) {
      return totals.entries
          .map((e) => StoreStock(storeName: e.key, quantity: e.value))
          .toList()
        ..sort((a, b) => a.storeName.compareTo(b.storeName));
    }
  }
  // No item code, or no matching rows — list distinct store names only (no quantity)
  final res = await client
      .from('stock_quantities')
      .select('store_name')
      .order('store_name');
  final seen = <String>{};
  return (res as List)
      .map((r) => (r['store_name'] ?? '').toString().trim())
      .where((n) => n.isNotEmpty && seen.add(n))
      .map((n) => StoreStock(storeName: n, quantity: 0))
      .toList();
});

// ── Dependency providers ───────────────────────────────────────────────────

final stockCheckRepositoryProvider = Provider<StockCheckRepository>((ref) {
  final ds = StockCheckRemoteDataSource(Supabase.instance.client);
  return StockCheckRepositoryImpl(ds);
});

// ── Family provider (one per quotationId) ─────────────────────────────────

class StockCheckNotifier
    extends FamilyAsyncNotifier<List<StockCheckItem>, int> {
  Timer? _debounce;

  @override
  Future<List<StockCheckItem>> build(int arg) async {
    ref.onDispose(() => _debounce?.cancel());
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

  Timer? _saveTimer;
  void _scheduleSave(StockCheckItem item) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () async {
      final repo = ref.read(stockCheckRepositoryProvider);
      await repo.saveCheck(quotationId: arg, item: item);
    });
  }

  bool get allChecked =>
      (state.valueOrNull ?? []).every((i) => i.isChecked);
}

final stockCheckProvider =
    AsyncNotifierProviderFamily<StockCheckNotifier, List<StockCheckItem>, int>(
  StockCheckNotifier.new,
);
