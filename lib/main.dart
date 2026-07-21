import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'firebase_options.dart';
import 'services/push_token_service.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/locale_provider.dart';
import 'core/services/seen_quotations_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/auth/domain/entities/warehouse_user.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/pending_transfers/presentation/screens/home_screen.dart';
import 'services/notification_service.dart';

/// FCM is mobile-only; the Windows build keeps its realtime + toast path.
bool get _firebaseSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_firebaseSupported) {
    // Dart-only Firebase init from firebase_options.dart (flutterfire
    // configure) — no google-services.json / gradle plugin needed.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await Supabase.initialize(
    url:     AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseKey,
  );

  await NotificationService.instance.init();
  await SeenQuotationsService.load();

  final prefs = await SharedPreferences.getInstance();
  final savedLocale = Locale(prefs.getString('app_locale') ?? 'en');

  runApp(
    ProviderScope(
      overrides: [
        initialLocaleProvider.overrideWithValue(savedLocale),
      ],
      child: const WarehouseApp(),
    ),
  );
}

class WarehouseApp extends ConsumerWidget {
  const WarehouseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale    = ref.watch(localeProvider);
    return MaterialApp(
      title: 'Warehouse Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends ConsumerWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppConstants.primaryColor,
          ),
        ),
      ),
      error: (err, st) => const LoginScreen(),
      data: (WarehouseUser? user) {
        if (user != null) {
          // Fire-and-forget: registers the FCM token + notification channel
          // (idempotent; mobile-only no-op elsewhere).
          PushTokenService.instance.register();
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
