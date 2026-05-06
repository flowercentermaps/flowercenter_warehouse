import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/warehouse_user.dart';
import '../../../../core/errors/failures.dart';

class AuthRemoteDataSource {
  final SupabaseClient _client;
  const AuthRemoteDataSource(this._client);

  Future<WarehouseUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) throw const AuthFailure('Sign in failed — no user returned.');

      // Fetch profile to check role
      final profile = await _client
          .from('profiles')
          .select('id, full_name, role')
          .eq('id', user.id)
          .single();

      final role = (profile['role'] as String? ?? '');
      if (role != 'warehouse_manager') {
        await _client.auth.signOut();
        throw const AccessDeniedFailure();
      }

      return WarehouseUser(
        id: user.id,
        email: user.email ?? email,
        name: profile['full_name'] as String? ?? '',
        role: role,
      );
    } on AuthFailure {
      rethrow;
    } on AccessDeniedFailure {
      rethrow;
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(e.toString());
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  WarehouseUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    // We don't have profile data here; return minimal user
    // The profile is loaded during sign-in and stored via provider
    return null;
  }
}
