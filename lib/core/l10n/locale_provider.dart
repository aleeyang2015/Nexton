import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_providers.dart';

/// Locales the app ships translations for. Lao is first — it is the
/// application default regardless of the device's system locale.
class AppLocales {
  AppLocales._();

  static const Locale lao = Locale('lo');
  static const Locale english = Locale('en');
  static const List<Locale> supported = [lao, english];
}

/// Persists the user's language choice and exposes it to the widget tree.
///
/// Reads/writes through [sharedPreferencesProvider] so the app's normal
/// storage wiring applies, but never lets storage being unavailable (e.g. a
/// test `ProviderScope` that hasn't overridden it) crash the app — it just
/// falls back to the Lao default with the switch working in-memory only.
class LocaleNotifier extends Notifier<Locale> {
  static const _prefsKey = 'app_locale';

  @override
  Locale build() {
    try {
      final saved = ref.watch(sharedPreferencesProvider).getString(_prefsKey);
      final match = AppLocales.supported
          .where((locale) => locale.languageCode == saved)
          .firstOrNull;
      if (match != null) return match;
    } catch (_) {
      // sharedPreferencesProvider isn't overridden here (e.g. in a test) —
      // fall through to the default below.
    }
    return AppLocales.lao;
  }

  Future<void> setLocale(Locale locale) async {
    if (!AppLocales.supported.contains(locale)) return;
    state = locale;
    try {
      await ref.read(sharedPreferencesProvider).setString(
        _prefsKey,
        locale.languageCode,
      );
    } catch (_) {
      // No persistence available — the in-memory switch still applies.
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
