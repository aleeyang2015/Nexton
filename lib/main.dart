import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/network/network_providers.dart';
import 'core/network/secure_store.dart';
import 'core/network/token_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app services
  await AppInitializer.initialize();

  // Opened once here so every provider downstream can stay synchronous.
  final prefs = await SharedPreferences.getInstance();
  final secureStore = FlutterSecureStore();

  // Must finish before anything reads a token: it moves a session left in
  // SharedPreferences by an older build into the keychain, then deletes it
  // from plain storage.
  await LegacySessionMigration(prefs: prefs, secureStore: secureStore).run();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        secureStoreProvider.overrideWithValue(secureStore),
      ],
      child: const App(),
    ),
  );
}
