import '../entities/warehouse_user.dart';

abstract interface class AuthRepository {
  Future<WarehouseUser> signIn({required String email, required String password});
  Future<void> signOut();
  WarehouseUser? get currentUser;
  Stream<WarehouseUser?> get authStateChanges;
}
