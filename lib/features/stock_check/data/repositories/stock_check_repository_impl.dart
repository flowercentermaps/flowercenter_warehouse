import '../../domain/entities/stock_check_item.dart';
import '../../domain/repositories/stock_check_repository.dart';
import '../datasources/stock_check_remote_datasource.dart';

class StockCheckRepositoryImpl implements StockCheckRepository {
  final StockCheckRemoteDataSource _ds;
  const StockCheckRepositoryImpl(this._ds);

  @override
  Future<List<StockCheckItem>> loadItems(int quotationId) =>
      _ds.loadItems(quotationId);

  @override
  Future<void> saveCheck({required int quotationId, required StockCheckItem item}) =>
      _ds.saveCheck(quotationId: quotationId, item: item);

  @override
  Future<void> markTransferred(int quotationId) =>
      _ds.markTransferred(quotationId);

  @override
  Future<void> sendForReview(int quotationId, {String? note}) =>
      _ds.sendForReview(quotationId, note: note);
}
