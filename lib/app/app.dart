import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/l10n/locale_provider.dart';
import '../core/theme/app_theme.dart';
import '../l10n/generated/app_localizations.dart';
import 'router/app_router.dart';

/// Main application widget
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,

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
    // Initialize services here
    // For example:
    // await Firebase.initializeApp();
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
