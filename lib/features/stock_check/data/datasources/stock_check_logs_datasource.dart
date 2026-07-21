import 'package:supabase_flutter/supabase_flutter.dart';

/// Read-only access to `quotation_stock_check_logs`.
///
/// The table is append-only and populated by a server-side trigger on
/// `quotation_stock_checks`. RLS allows SELECT to warehouse_manager + admin.
class StockCheckLogsDataSource {
  final SupabaseClient _client;
  const StockCheckLogsDataSource(this._client);

  /// All change-log entries for one quotation, newest first.
  Future<List<Map<String, dynamic>>> fetchForQuotation(int quotationId) async {
    final res = await _client
        .from('quotation_stock_check_logs')
        .select(
          'id, quotation_item_id, supplier_code, product_name, '
          'changed_by_name, changed_at, before_status, after_status, '
          'before_qty, after_qty, shortage_reason',
        )
        .eq('quotation_id', quotationId)
        .order('changed_at', ascending: false);
    return (res as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Recent shortage events for a single product (matched by supplier_code).
  /// `after_status` of `partial` or `out_of_stock` counts as a shortage.
  Future<List<Map<String, dynamic>>> fetchShortagesForSupplier({
    required String supplierCode,
    int days = 30,
  }) async {
    if (supplierCode.isEmpty) return const [];
    final since =
        DateTime.now().toUtc().subtract(Duration(days: days)).toIso8601String();
    final res = await _client
        .from('quotation_stock_check_logs')
        .select(
          'id, quotation_id, changed_at, after_status, after_qty, '
          'shortage_reason, changed_by_name',
        )
        .eq('supplier_code', supplierCode)
        .inFilter('after_status', ['partial', 'out_of_stock'])
        .gte('changed_at', since)
        .order('changed_at', ascending: false)
        .limit(100);
    return (res as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
