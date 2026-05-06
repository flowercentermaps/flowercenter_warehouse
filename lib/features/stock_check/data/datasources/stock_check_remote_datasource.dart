import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/check_status.dart';
import '../../domain/entities/stock_check_item.dart';

class StockCheckRemoteDataSource {
  final SupabaseClient _client;
  const StockCheckRemoteDataSource(this._client);

  /// Load quotation_items + merge with existing stock check rows.
  Future<List<StockCheckItem>> loadItems(int quotationId) async {
    // 1. Fetch quotation items
    final itemsRes = await _client
        .from('quotation_items')
        .select('id, product_name, item_code, quantity')
        .eq('quotation_id', quotationId)
        .order('id');

    // 2. Fetch existing check rows
    final checksRes = await _client
        .from('quotation_stock_checks')
        .select()
        .eq('quotation_id', quotationId);

    // Build a map: quotation_item_id → check row
    final checksMap = <int, Map<String, dynamic>>{};
    for (final c in (checksRes as List)) {
      final row = Map<String, dynamic>.from(c as Map);
      final qItemId = (row['quotation_item_id'] as num?)?.toInt();
      if (qItemId != null) checksMap[qItemId] = row;
    }

    return (itemsRes as List).map((raw) {
      final e = Map<String, dynamic>.from(raw as Map);
      final id = (e['id'] as num).toInt();
      final check = checksMap[id];
      return StockCheckItem(
        quotationItemId:   id,
        productName:       e['product_name'] as String? ?? '',
        itemCode:          e['item_code']     as String? ?? '',
        supplierCode:      '',
        quantityNeeded:    double.tryParse(e['quantity']?.toString() ?? '0') ?? 0,
        status:            CheckStatus.fromDb(check?['status'] as String?),
        quantityAvailable: double.tryParse(check?['quantity_available']?.toString() ?? ''),
        shortageReason:    check?['shortage_reason'] as String?,
        suggestion:        check?['suggestion'] as String?,
        warehouseLocation: check?['warehouse_location'] as String?,
        checkRowId:        (check?['id'] as num?)?.toInt(),
      );
    }).toList();
  }

  /// Upsert a stock check row for one item.
  Future<void> saveCheck({
    required int quotationId,
    required StockCheckItem item,
  }) async {
    final uid = _client.auth.currentUser?.id;
    final payload = <String, dynamic>{
      'quotation_id':        quotationId,
      'quotation_item_id':   item.quotationItemId,
      'supplier_code':       item.supplierCode,
      'product_name':        item.productName,
      'quantity_needed':     item.quantityNeeded,
      'status':              item.status.dbValue,
      'quantity_available':  item.quantityAvailable,
      'shortage_reason':     item.shortageReason,
      'suggestion':          item.suggestion,
      'warehouse_location':  item.warehouseLocation,
      'checked_by':          uid,
      'checked_at':          DateTime.now().toUtc().toIso8601String(),
    };

    if (item.checkRowId != null) {
      // Update existing row
      await _client
          .from('quotation_stock_checks')
          .update(payload)
          .eq('id', item.checkRowId!);
    } else {
      // Insert new row
      final res = await _client
          .from('quotation_stock_checks')
          .insert(payload)
          .select('id')
          .single();
      item.checkRowId = (res['id'] as num).toInt();
    }
  }

  /// Call the RPC to mark quotation as transferred.
  Future<void> markTransferred(int quotationId) async {
    await _client.rpc(
      'mark_quotation_transferred',
      params: {'p_quotation_id': quotationId},
    );
  }
}
