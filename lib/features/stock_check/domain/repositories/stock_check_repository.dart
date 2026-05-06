import '../entities/stock_check_item.dart';

abstract interface class StockCheckRepository {
  /// Returns quotation items merged with any existing check data.
  Future<List<StockCheckItem>> loadItems(int quotationId);

  /// Upsert a single item's check result.
  Future<void> saveCheck({
    required int quotationId,
    required StockCheckItem item,
  });

  /// Mark the quotation as transferred via RPC.
  Future<void> markTransferred(int quotationId);
}
