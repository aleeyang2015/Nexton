import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/l10n/locale_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_toast.dart';
import '../features/notifications/data/push_background_handler.dart';
import '../features/notifications/presentation/providers/push_notifications_notifier.dart';
import '../l10n/generated/app_localizations.dart';
import 'router/app_router.dart';

/// Main application widget
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    // Keeps push registration alive for the app's lifetime without rebuilding
    // the app each time it changes.
    ref.listen(pushNotificationsProvider, (_, _) {});

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,

      // Lets [AppToast] reach a messenger from anywhere, with no Scaffold
      // context in hand.
      scaffoldMessengerKey: rootScaffoldMessengerKey,

      // Localization Configuration — Lao is the app default; see
      // core/l10n/locale_provider.dart.
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Router Configuration
      routerConfig: router,

      // Builder for wrapping widgets with providers or services
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Prevent text scaling issues
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
    );
  }
}

/// App initialization helper
class AppInitializer {
  /// Initialize services that must be ready before the first frame.
  /// Dependencies themselves are wired through Riverpod providers, not here.
  static Future<void> initialize() async {
    // Reads google-services.json (Android) / GoogleService-Info.plist (iOS).
    await Firebase.initializeApp();
    // Must be registered before runApp so a push that wakes a closed app has
    // somewhere to go.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize services here
    // For example:
    // await Hive.initFlutter();
    // await SharedPreferences.getInstance();
  }

  /// Perform app cleanup
  static Future<void> cleanup() async {
    // Cleanup resources here
    // For example:
    // await Hive.close();
  }
}
