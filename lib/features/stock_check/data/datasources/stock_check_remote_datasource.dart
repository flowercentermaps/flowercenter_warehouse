import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/check_status.dart';
import '../../domain/entities/stock_check_item.dart';
import '../../domain/entities/store_allocation.dart';
import '../../domain/repositories/stock_check_repository.dart';

class StockCheckRemoteDataSource {
  final SupabaseClient _client;
  const StockCheckRemoteDataSource(this._client);

  /// Load quotation_items + merge with existing stock check rows.
  /// All item types are included: flowers, trees, and custom arrangements.
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

    // 2. Collect product_ids (non-null) to look up product_type
    final productIds = allItems
        .map((e) => e['product_id'])
        .where((id) => id != null)
        .map((id) => (id as num).toInt())
        .toSet()
        .toList();

    final Map<int, Map<String, dynamic>> productMap = {};

    if (productIds.isNotEmpty) {
      final plRes = await _client
          .from('price_list_items')
          .select('id, product_type, item_code, supplier_code, article_code_id, image_path, barcode')
          .inFilter('id', productIds);

      for (final row in (plRes as List)) {
        final r = Map<String, dynamic>.from(row as Map);
        final pid = (r['id'] as num?)?.toInt();

        if (pid != null) {
          productMap[pid] = r;
        }
      }
    }

    // 3. Include all items — flowers, trees, and custom arrangements
    final checkedItems = allItems.toList();

    // 4. Fetch existing check rows
    final checksRes = await _client
        .from('quotation_stock_checks')
        .select()
        .eq('quotation_id', quotationId);

    final checksMap = <int, Map<String, dynamic>>{};
    for (final c in (checksRes as List)) {
      final row = Map<String, dynamic>.from(c as Map);
      final qItemId = (row['quotation_item_id'] as num?)?.toInt();
      if (qItemId != null) checksMap[qItemId] = row;
    }

    return checkedItems.map((e) {
      final id = (e['id'] as num).toInt();
      final check = checksMap[id];
      final pid = (e['product_id'] as num?)?.toInt();
      final productRow = pid == null ? null : productMap[pid];

      final productType = (productRow?['product_type'] ?? '').toString();
      final isTree = productType == 'tree';

      final itemCode     = (e['item_code'] ?? productRow?['item_code'] ?? '').toString();
      final supplierCode = (productRow?['supplier_code'] ?? itemCode).toString();
      final articleCodeId = (productRow?['article_code_id'] ?? '').toString();
      final imagePath    = (productRow?['image_path'] ?? '').toString();
      final imageUrl    = imagePath.isEmpty
          ? null
          : _client.storage.from('product-images').getPublicUrl(imagePath);
      final barcode = (productRow?['barcode'] ?? '').toString();

      return StockCheckItem(
        quotationItemId:   id,
        productName:       e['product_name'] as String? ?? '',
        itemCode:          itemCode,
        supplierCode:      supplierCode,
        isTree:            isTree,
        articleCodeId:     articleCodeId.isEmpty ? null : articleCodeId,
        imageUrl:          imageUrl,
        barcode:           barcode.isEmpty ? null : barcode,
        quantityNeeded:    double.tryParse(e['quantity']?.toString() ?? '0') ?? 0,
        status:            CheckStatus.fromDb(check?['status'] as String?),
        quantityAvailable: double.tryParse(check?['quantity_available']?.toString() ?? ''),
        shortageReason:    check?['shortage_reason'] as String?,
        suggestion:        check?['suggestion'] as String?,
        storeAllocations: (() {
          final allocs = _parseAllocations(check?['store_allocations']);
          if (allocs.isNotEmpty) return allocs;
          final loc = (check?['warehouse_location'] as String? ?? '').trim();
          final qty = (check?['quantity_available'] as num?)?.toDouble();
          if (loc.isNotEmpty && qty != null && qty > 0) {
            return [StoreAllocation(storeName: loc, qty: qty)];
          }
          return const <StoreAllocation>[];
        })(),
        checkRowId:        (check?['id'] as num?)?.toInt(),
      );
    }).toList();
  }

  /// Parse a raw JSON value from Supabase into a list of [StoreAllocation].
  static List<StoreAllocation> _parseAllocations(dynamic raw) {
    if (raw == null) return const [];
    final list = raw is List ? raw : (raw is String ? [] : []);
    return list
        .whereType<Map>()
        .map((m) => StoreAllocation.fromJson(Map<String, dynamic>.from(m)))
        .where((a) => a.storeName.isNotEmpty)
        .toList();
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
      'quantity_available':  item.totalAllocated > 0 ? item.totalAllocated : item.quantityAvailable,
      'shortage_reason':     item.shortageReason,
      'suggestion':          item.suggestion,
      'store_allocations':   item.storeAllocations.map((a) => a.toJson()).toList(),
      'warehouse_location':  item.storeAllocations.isEmpty
          ? null
          : item.storeAllocations.map((a) => a.storeName).join(', '),
      'checked_by':          uid,
      'checked_at':          DateTime.now().toUtc().toIso8601String(),
    };

    if (item.checkRowId != null) {
      // Try to update the existing row; if it was deleted externally (e.g. by
      // "Re-approve for Transfer"), the update will match 0 rows — fall back to INSERT.
      final updated = await _client
          .from('quotation_stock_checks')
          .update(payload)
          .eq('id', item.checkRowId!)
          .select('id');
      if ((updated as List).isEmpty) {
        // Row no longer exists — insert fresh.
        item.checkRowId = null;
        final res = await _client
            .from('quotation_stock_checks')
            .insert(payload)
            .select('id')
            .single();
        item.checkRowId = (res['id'] as num).toInt();
      }
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
  ///
  /// For the auto-transfer-sale flow, `transfer_status` is set SERVER-SIDE by
  /// process_jobs.js only once the Al-Khazen job genuinely succeeds — never
  /// eagerly here. Setting it eagerly used to leave a quotation showing
  /// "Transferred" even when the job later failed (e.g. NO_FIXED_PRICE) or
  /// was still processing after our poll window ran out. Gated by a feature
  /// flag for easy revert.
  Future<MarkTransferResult> markTransferred(int quotationId,
      {String sellAs = 'hamasat'}) async {
    // Manual: mark transferred with no Al-Khazen job (user handles it by hand).
    if (sellAs == 'manual') {
      await _client.rpc('mark_transferred_manual',
          params: {'p_quotation_id': quotationId});
      return const MarkTransferResult(MarkOutcome.manual);
    }

    if (!AppConstants.enableUaeAutoTransferSale) {
      // No Al-Khazen job in this mode — nothing async to wait for, so this is
      // the only path where marking transferred immediately is correct.
      await _client.rpc('mark_quotation_transferred',
          params: {'p_quotation_id': quotationId});
      return const MarkTransferResult(MarkOutcome.success);
    }

    // Queue the Al-Khazen transfer/sale job (RPC returns its id), then wait for
    // the server to run it — poll by primary key, which is reliable.
    final jobId = await _client.rpc('queue_uae_transfer_sale',
        params: {'p_quotation_id': quotationId, 'p_sell_as': sellAs});

    for (var i = 0; i < 20; i++) {
      await Future.delayed(const Duration(seconds: 1));
      final row = await _client
          .from('alkhazen_jobs')
          .select('status, error')
          .eq('id', jobId)
          .maybeSingle();
      if (row == null) continue;
      final status = (row['status'] ?? '').toString();
      final err    = (row['error'] ?? '').toString();
      // The server already set transfer_status='transferred' as part of
      // marking this job 'done' — no redundant client-side call needed.
      if (status == 'done') return const MarkTransferResult(MarkOutcome.success);
      if (status == 'failed') {
        if (err.startsWith('NO_FIXED_PRICE')) {
          return MarkTransferResult(MarkOutcome.noFixedPrice,
              err.replaceFirst('NO_FIXED_PRICE:', '').trim());
        }
        return MarkTransferResult(MarkOutcome.error, err);
      }
    }
    // Still processing after the wait — transfer_status stays untouched; the
    // server will set it (or leave it alone on failure) whenever the job
    // actually finishes, with no further action needed here.
    return const MarkTransferResult(MarkOutcome.timeout);
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
