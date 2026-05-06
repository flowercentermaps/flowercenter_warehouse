import '../../domain/entities/pending_quotation.dart';
import '../../domain/repositories/pending_transfers_repository.dart';
import '../datasources/pending_transfers_remote_datasource.dart';

class PendingTransfersRepositoryImpl implements PendingTransfersRepository {
  final PendingTransfersRemoteDataSource _ds;
  const PendingTransfersRepositoryImpl(this._ds);

  @override
  Future<List<PendingQuotation>> fetchPendingTransfers() => _ds.fetchPendingTransfers();

  @override
  Future<List<PendingQuotation>> fetchTransferred() => _ds.fetchTransferred();
}
