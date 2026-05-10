import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/check_status.dart';
import '../../domain/entities/stock_check_item.dart';

class StockCheckRemoteDataSource {
  final SupabaseClient _client;
  const StockCheckRemoteDataSource(this._client);

  /// Load quotation_items + merge with existing stock check rows.
  /// Trees (product_type = 'tree') and custom arrangements are excluded —
  /// only flower items need warehouse transfer.
  Future<List<StockCheckItem>> loadItems(int quotationId) async {
    // 1. Fetch quotation items (include product_id and item_type for filtering)
    final itemsRes = await _client
        .from('quotation_items')
        .select('id, product_name, item_code, quantity, item_type, product_id')
        .eq('quotation_id', quotationId)
        .order('id');

    final allItems = (itemsRes as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    Logger().w(allItems.first);
    // 2. Collect product_ids (non-null) to look up product_type
    final productIds = allItems
        .map((e) => e['product_id'])
        .where((id) => id != null)
        .map((id) => (id as num).toInt())
        .toSet()
        .toList();
    Logger().i(productIds.first);
    // 3. Fetch product_type for those ids
    // final Map<int, String> productTypeMap = {};
    // if (productIds.isNotEmpty) {
    //   final plRes = await _client
    //       .from('price_list_items')
    //       .select('id, product_type, item_code, supplier_code')
    //       // .select('id, product_type')
    //       .inFilter('id', productIds);
    //   for (final row in (plRes as List)) {
    //     final r = row as Map;
    //     final pid = (r['id'] as num?)?.toInt();
    //     if (pid != null) productTypeMap[pid] = (r['product_type'] ?? '').toString();
    //   }
    // }
    final Map<int, Map<String, dynamic>> productMap = {};

    if (productIds.isNotEmpty) {
      final plRes = await _client
          .from('price_list_items')
          .select('id, product_type, item_code, supplier_code')
          .inFilter('id', productIds);

      for (final row in (plRes as List)) {
        final r = Map<String, dynamic>.from(row as Map);
        final pid = (r['id'] as num?)?.toInt();

        if (pid != null) {
          productMap[pid] = r;
        }
      }
    }

    // 4. Exclude trees and custom arrangements — only flowers go to warehouse
    final flowerItems = allItems.where((e) {
      final itemType = (e['item_type'] ?? '').toString();
      if (itemType == 'custom_arrangement') return false;
      final pid = (e['product_id'] as num?)?.toInt();
      final productType = pid != null
          ? (productMap[pid]?['product_type'] ?? '').toString()
          : '';
      // final productType = pid != null ? (productTypeMap[pid] ?? '') : '';
      return productType != 'tree';
    }).toList();

    // 5. Fetch existing check rows
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

    return flowerItems.map((e) {
      final id = (e['id'] as num).toInt();
      final check = checksMap[id];
      final pid = (e['product_id'] as num?)?.toInt();
      final productRow = pid == null ? null : productMap[pid];

      final itemCode = (e['item_code'] ?? productRow?['item_code'] ?? '').toString();
      final supplierCode = (productRow?['supplier_code'] ?? itemCode).toString();
      return StockCheckItem(
        quotationItemId:   id,
        productName:       e['product_name'] as String? ?? '',
        itemCode: itemCode,
        supplierCode: supplierCode,
        // itemCode:          e['item_code']     as String? ?? '',
        // supplierCode:      '',
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

  Future<void> sendForReview(int quotationId, {String? note}) async {
    await _client.rpc(
      'send_quotation_for_sales_review',
      params: {
        'p_quotation_id': quotationId,
        'p_note': note,
      },
    );
  }
}
