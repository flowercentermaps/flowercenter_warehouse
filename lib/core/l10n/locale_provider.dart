import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(Locale initial) : super(initial);

  Future<void> toggle() async {
    final next = state.languageCode == 'en'
        ? const Locale('ar')
        : const Locale('en');
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, next.languageCode);
  }
}

/// Overridden in main() with the persisted locale value.
final initialLocaleProvider = Provider<Locale>((ref) => const Locale('en'));

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref.read(initialLocaleProvider));
});
