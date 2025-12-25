import 'package:get_it/get_it.dart';

/// Global service locator instance
final GetIt sl = GetIt.instance;

/// Configure dependency injection
Future<void> configureDependencies() async {
  // Register services here
  // Example:
  // sl.registerLazySingleton(() => Dio());
  // sl.registerLazySingleton(() => ApiClient(sl()));
}

/// Easy access to service locator
class DI {
  /// Get an instance of [T]
  static T get<T extends Object>() => sl<T>();

  /// Register a singleton instance
  static void registerSingleton<T extends Object>(T instance) {
    sl.registerSingleton<T>(instance);
  }

  /// Register a factory
  static void registerFactory<T extends Object>(T Function() factoryFunc) {
    sl.registerFactory<T>(factoryFunc);
  }

  /// Register a lazy singleton
  static void registerLazySingleton<T extends Object>(T Function() factoryFunc) {
    sl.registerLazySingleton<T>(factoryFunc);
  }

  /// Clear all registered instances
  Future<void> reset() async {
    await sl.reset();
  }

  /// Check if [T] is registered
  static bool isRegistered<T extends Object>() {
    return sl.isRegistered<T>();
  }
}