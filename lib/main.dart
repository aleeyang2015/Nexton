import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/router/app_router.dart';
import 'core/network/network_providers.dart';
import 'core/network/secure_store.dart';
import 'core/network/token_storage.dart';
import 'core/upload/domain/local_file.dart';
import 'core/upload/presentation/file_capture.dart';
import 'core/upload/upload_providers.dart';
import 'features/auth/auth_providers.dart';
import 'features/notifications/notifications_providers.dart';
import 'features/notifications/presentation/providers/push_notifications_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app services; push stays off when Firebase could not start.
  final pushAvailable = await AppInitializer.initialize();

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
        pushAvailableProvider.overrideWithValue(pushAvailable),
        // Sign-out signs this phone off for push first (#52).
        beforeSignOutProvider.overrideWith(
          (ref) => ref.watch(signOutThisDeviceProvider),
        ),
        secureStoreProvider.overrideWithValue(secureStore),
        // The shared photo/file picker opens the App's own camera screen.
        fileCaptureProvider.overrideWithValue(
          FilePickerCapture(
            openCamera: (context) =>
                context.push<LocalFile>(AppRoutes.cameraCapture),
          ),
        ),
      ],
      child: const App(),
    ),
  );
}
