import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/pending_quotation.dart';

class PendingTransfersRemoteDataSource {
  final SupabaseClient _client;
  const PendingTransfersRemoteDataSource(this._client);

  Future<List<PendingQuotation>> fetchPendingTransfers() async {
    final res = await _client
        .from('quotations')
        .select('id, quote_no, customer_name, company_name, net_total, created_at, quotation_items(id)')
        .eq('transfer_status', 'pending_transfer')
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => PendingQuotation.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<PendingQuotation>> fetchTransferred() async {
    final res = await _client
        .from('quotations')
        .select('id, quote_no, customer_name, company_name, net_total, created_at, quotation_items(id)')
        .eq('transfer_status', 'transferred')
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => PendingQuotation.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
