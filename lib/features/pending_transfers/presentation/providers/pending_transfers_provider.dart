import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/seen_quotations_service.dart';
import '../../data/datasources/pending_transfers_remote_datasource.dart';
import '../../data/repositories/pending_transfers_repository_impl.dart';
import '../../domain/entities/pending_quotation.dart';
import '../../domain/repositories/pending_transfers_repository.dart';
import '../../../../services/notification_service.dart';

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
  Set<int> _knownIds = {};
  bool _initialized = false;

  @override
  Future<List<PendingQuotation>> build() async {
    _setupRealtime();
    ref.onDispose(_cancelRealtime);
    final result = await _fetch();
    // Seed known IDs so we only notify about arrivals after startup
    _knownIds = result.map((q) => q.id).toSet();

    // On the very first launch ever, mark all current pending quotations as
    // already-seen so the warehouse doesn't open the app to a wall of gold
    // dots for things that arrived weeks before installation. After that,
    // only newly arriving quotations get the unread treatment.
    final prefs = await SharedPreferences.getInstance();
    const firstRunKey = 'warehouse_first_run_seeded_v1';
    if (!(prefs.getBool(firstRunKey) ?? false)) {
      await SeenQuotationsService.markManySeen(_knownIds);
      await prefs.setBool(firstRunKey, true);
    }

    _initialized = true;
    return result;
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
      final previousIds = _knownIds;
      state = await AsyncValue.guard(_fetch);

      if (_initialized) {
        final current = state.valueOrNull ?? [];
        final currentIds = current.map((q) => q.id).toSet();
        final newIds = currentIds.difference(previousIds);

        for (final newId in newIds) {
          final q = current.firstWhere((q) => q.id == newId);
          NotificationService.instance.showNewRequestNotification(
            id: newId,
            quoteNo: q.quoteNo,
            customerName: q.customerName.isNotEmpty
                ? q.customerName
                : q.companyName,
            urgent: q.urgent,
          );
        }

        _knownIds = currentIds;
      }
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
