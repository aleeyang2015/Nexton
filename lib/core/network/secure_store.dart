import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Key/value storage backed by the platform keychain.
///
/// Kept behind an interface for two reasons: tests need an in-memory double,
/// and the platform plugin is an implementation detail no other layer should
/// import.
abstract class SecureStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// iOS/macOS Keychain, Android EncryptedSharedPreferences, and the equivalent
/// secure store on the remaining platforms.
class FlutterSecureStore implements SecureStore {
  static const _androidOptions = AndroidOptions(
    // Backed by Jetpack Security rather than plain SharedPreferences.
    encryptedSharedPreferences: true,
  );

  static const _iosOptions = IOSOptions(
    // Readable only once the device has been unlocked at least once since
    // boot, and never synced to another device via iCloud Keychain.
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final FlutterSecureStorage _storage;

  FlutterSecureStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: _androidOptions,
            iOptions: _iosOptions,
          );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
