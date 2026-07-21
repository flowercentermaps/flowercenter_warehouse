import '../entities/stock_check_item.dart';

/// Outcome of a "Mark as Transferred" action.
enum MarkOutcome {
  success,       // transfer/sale job completed in Al-Khazen
  manual,        // marked transferred with no Al-Khazen job (handled by hand)
  noFixedPrice,  // job failed: items lack an Al-Khazen fixed price (see detail)
  timeout,       // job queued but still processing (will finish on the server)
  error,         // job failed for another reason (see detail)
}

class MarkTransferResult {
  final MarkOutcome outcome;
  final String? detail; // item list for noFixedPrice, or error message
  const MarkTransferResult(this.outcome, [this.detail]);
}

abstract interface class StockCheckRepository {
  /// Returns quotation items merged with any existing check data.
  Future<List<StockCheckItem>> loadItems(int quotationId);

  /// Upsert a single item's check result.
  Future<void> saveCheck({
    required int quotationId,
    required StockCheckItem item,
  });

  /// Mark the quotation as transferred via RPC.
  /// [sellAs]: 'hamasat' (transfer+sale+purchase), 'flowercenter' (transfer only),
  /// or 'manual' (no Al-Khazen job — handled by hand). For the auto modes this
  /// waits for the Al-Khazen job and reports its outcome.
  Future<MarkTransferResult> markTransferred(int quotationId, {String sellAs});

  Future<void> sendForReview(int quotationId, {String? note});
}
