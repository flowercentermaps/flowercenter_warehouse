import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/pending_transfers_remote_datasource.dart';
import '../../data/repositories/pending_transfers_repository_impl.dart';
import '../../domain/entities/pending_quotation.dart';
import '../../domain/repositories/pending_transfers_repository.dart';

// ── Dependency providers ───────────────────────────────────────────────────

final _pendingTransfersDsProvider = Provider<PendingTransfersRemoteDataSource>(
  (ref) => PendingTransfersRemoteDataSource(Supabase.instance.client),
);

final pendingTransfersRepositoryProvider = Provider<PendingTransfersRepository>(
  (ref) => PendingTransfersRepositoryImpl(ref.read(_pendingTransfersDsProvider)),
);

// ── Notifier ───────────────────────────────────────────────────────────────

class PendingTransfersNotifier
    extends AsyncNotifier<List<PendingQuotation>> {
  RealtimeChannel? _channel;

  @override
  Future<List<PendingQuotation>> build() async {
    _setupRealtime();
    ref.onDispose(_cancelRealtime);
    return _fetch();
  }

  Future<List<PendingQuotation>> _fetch() {
    final repo = ref.read(pendingTransfersRepositoryProvider);
    return repo.fetchPendingTransfers();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  void _setupRealtime() {
    final client = Supabase.instance.client;
    _channel = client
        .channel('warehouse-pending-${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'quotations',
          callback: (_) => _silentRefresh(),
        )
        .subscribe();
  }

  Timer? _debounce;
  void _silentRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      state = await AsyncValue.guard(_fetch);
    });
  }

  void _cancelRealtime() {
    _debounce?.cancel();
    final ch = _channel;
    _channel = null;
    if (ch != null) Supabase.instance.client.removeChannel(ch);
  }
}

final pendingTransfersProvider =
    AsyncNotifierProvider<PendingTransfersNotifier, List<PendingQuotation>>(
  PendingTransfersNotifier.new,
);

// ── Transferred tab provider ───────────────────────────────────────────────

class TransferredNotifier extends AsyncNotifier<List<PendingQuotation>> {
  RealtimeChannel? _channel;

  @override
  Future<List<PendingQuotation>> build() async {
    _setupRealtime();
    ref.onDispose(_cancelRealtime);
    return _fetch();
  }

  Future<List<PendingQuotation>> _fetch() {
    final repo = ref.read(pendingTransfersRepositoryProvider);
    return repo.fetchTransferred();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  void _setupRealtime() {
    final client = Supabase.instance.client;
    _channel = client
        .channel('warehouse-transferred-${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'quotations',
          callback: (_) => _silentRefresh(),
        )
        .subscribe();
  }

  Timer? _debounce;
  void _silentRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      state = await AsyncValue.guard(_fetch);
    });
  }

  void _cancelRealtime() {
    _debounce?.cancel();
    final ch = _channel;
    _channel = null;
    if (ch != null) Supabase.instance.client.removeChannel(ch);
  }
}

final transferredProvider =
    AsyncNotifierProvider<TransferredNotifier, List<PendingQuotation>>(
  TransferredNotifier.new,
);
