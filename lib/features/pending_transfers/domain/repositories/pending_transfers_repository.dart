import '../entities/pending_quotation.dart';

abstract interface class PendingTransfersRepository {
  Future<List<PendingQuotation>> fetchPendingTransfers();
  Future<List<PendingQuotation>> fetchTransferred();
}
