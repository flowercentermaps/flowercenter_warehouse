import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/warehouse_user.dart';
import '../../domain/repositories/auth_repository.dart';

// ── Dependency providers ───────────────────────────────────────────────────

final _supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final _authDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.read(_supabaseClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.read(_authDataSourceProvider)),
);

// ── Auth state notifier ────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<WarehouseUser?> {
  @override
  Future<WarehouseUser?> build() async {
    // Only reset to null when session is definitively gone (AsyncData with null),
    // never on AsyncLoading — otherwise sign-in races with the stream firing.
    ref.listen<AsyncValue<Session?>>(_supabaseSessionProvider, (_, next) {
      if (next is AsyncData && next.value == null) {
        state = const AsyncData(null);
      }
    });

    // Restore session after hot restart / app resume
    final client = Supabase.instance.client;
    final existing = client.auth.currentSession;
    if (existing != null) {
      try {
        final profile = await client
            .from('profiles')
            .select('id, full_name, role')
            .eq('id', existing.user.id)
            .single();
        final role = (profile['role'] as String? ?? '');
        if (role == 'warehouse_manager') {
          final user = WarehouseUser(
            id: existing.user.id,
            email: existing.user.email ?? '',
            name: profile['full_name'] as String? ?? '',
            role: role,
          );
          // Cache in repo so currentUser returns it
          (ref.read(authRepositoryProvider) as AuthRepositoryImpl)
              .cacheUser(user);
          return user;
        }
      } catch (_) {
        // Session exists but profile fetch failed — let user sign in manually
      }
    }

    return ref.read(authRepositoryProvider).currentUser;
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    final repo = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard(
      () => repo.signIn(email: email, password: password),
    );
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, WarehouseUser?>(
  AuthNotifier.new,
);

// Internal provider to watch session state
final _supabaseSessionProvider = StreamProvider<Session?>(
  (ref) => Supabase.instance.client.auth.onAuthStateChange
      .map((event) => event.session),
);
