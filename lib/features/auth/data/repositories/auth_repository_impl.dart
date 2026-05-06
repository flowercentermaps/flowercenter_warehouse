import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/warehouse_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _ds;
  WarehouseUser? _cachedUser;

  AuthRepositoryImpl(this._ds);

  @override
  Future<WarehouseUser> signIn({
    required String email,
    required String password,
  }) async {
    final user = await _ds.signIn(email: email, password: password);
    _cachedUser = user;
    return user;
  }

  /// Called by AuthNotifier to restore a user from an existing Supabase session.
  void cacheUser(WarehouseUser user) => _cachedUser = user;

  @override
  Future<void> signOut() async {
    _cachedUser = null;
    await _ds.signOut();
  }

  @override
  WarehouseUser? get currentUser => _cachedUser;

  @override
  Stream<WarehouseUser?> get authStateChanges =>
      Supabase.instance.client.auth.onAuthStateChange.map((event) {
        if (event.session == null) {
          _cachedUser = null;
          return null;
        }
        return _cachedUser;
      });
}
