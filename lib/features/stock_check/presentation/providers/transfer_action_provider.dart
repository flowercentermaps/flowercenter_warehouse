// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'stock_check_provider.dart';
//
// class TransferActionNotifier extends FamilyAsyncNotifier<void, int> {
//   @override
//   Future<void> build(int arg) async {}
//
//   Future<bool> markTransferred() async {
//     state = const AsyncLoading();
//     final repo = ref.read(stockCheckRepositoryProvider);
//     final result = await AsyncValue.guard(() => repo.markTransferred(arg));
//     state = result;
//     return result is AsyncData;
//   }
// }
//
// final transferActionProvider =
//     AsyncNotifierProviderFamily<TransferActionNotifier, void, int>(
//   TransferActionNotifier.new,
// );

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/stock_check_repository.dart';
import 'stock_check_provider.dart';

/// Selling entity chosen before "Mark as Transferred", per quotation.
/// 'hamasat' = transfer + sale + Hamasat purchase; 'flowercenter' = transfer only.
final sellAsProvider =
    StateProvider.family<String, int>((ref, quotationId) => 'hamasat');

class TransferActionNotifier extends FamilyAsyncNotifier<void, int> {
  @override
  Future<void> build(int arg) async {}

  /// Returns the Al-Khazen outcome (or error result) so the UI can react —
  /// e.g. show the no-fixed-price dialog.
  Future<MarkTransferResult> markTransferred({String sellAs = 'hamasat'}) async {
    state = const AsyncLoading();
    final repo = ref.read(stockCheckRepositoryProvider);
    final result =
        await AsyncValue.guard(() => repo.markTransferred(arg, sellAs: sellAs));
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    return result.valueOrNull ??
        MarkTransferResult(MarkOutcome.error, result.error?.toString());
  }

  Future<bool> sendForReview({String? note}) async {
    state = const AsyncLoading();
    final repo = ref.read(stockCheckRepositoryProvider);
    final result = await AsyncValue.guard(
          () => repo.sendForReview(arg, note: note),
    );
    state = result;
    return result is AsyncData;
  }
}

final transferActionProvider =
AsyncNotifierProviderFamily<TransferActionNotifier, void, int>(
  TransferActionNotifier.new,
);