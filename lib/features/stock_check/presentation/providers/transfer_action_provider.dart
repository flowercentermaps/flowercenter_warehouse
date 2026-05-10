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
import 'stock_check_provider.dart';

class TransferActionNotifier extends FamilyAsyncNotifier<void, int> {
  @override
  Future<void> build(int arg) async {}

  Future<bool> markTransferred() async {
    state = const AsyncLoading();
    final repo = ref.read(stockCheckRepositoryProvider);
    final result = await AsyncValue.guard(() => repo.markTransferred(arg));
    state = result;
    return result is AsyncData;
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