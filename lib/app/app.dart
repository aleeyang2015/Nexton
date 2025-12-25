import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/injection_container.dart';
import 'router/app_router.dart';

/// Main application widget
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Next On',
      debugShowCheckedModeBanner: false,

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
            textScaleFactor: 1.0, // Prevent text scaling issues
          ),
          child: child!,
        );
      },
    );
  }
}

/// App initialization helper
class AppInitializer {
  /// Initialize app services and dependencies
  static Future<void> initialize() async {
    // Initialize dependency injection
    await configureDependencies();

    // Initialize other services here
    // For example:
    // await Firebase.initializeApp();
    // await Hive.initFlutter();
    // await SharedPreferences.getInstance();
  }

  /// Perform app cleanup
  static Future<void> cleanup() async {
    // Cleanup resources here
    // For example:
    // await DI.reset();
    // await Hive.close();
  }
}