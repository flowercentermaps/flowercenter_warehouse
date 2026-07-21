import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/pending_quotation.dart';

class PendingTransfersRemoteDataSource {
  final SupabaseClient _client;
  const PendingTransfersRemoteDataSource(this._client);

  static const _columns =
      'id, quote_no, customer_name, company_name, customer_phone, '
      'salesperson_name, net_total, created_at, delivery_type, '
      'transfer_urgent, quotation_items(id)';

  Future<List<PendingQuotation>> fetchPendingTransfers() async {
    final res = await _client
        .from('quotations')
        .select(_columns)
        .eq('transfer_status', 'pending_transfer')
        // Urgent requests jump the queue, newest first within each group.
        .order('transfer_urgent', ascending: false)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => PendingQuotation.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<PendingQuotation>> fetchTransferred() async {
    final res = await _client
        .from('quotations')
        .select(_columns)
        .eq('transfer_status', 'transferred')
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => PendingQuotation.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
