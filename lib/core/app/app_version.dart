import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The App's real version (#57), as the stores know it: `1.0.1`, never the
/// build number (`1.0.1+5`). Set once in `main` from the platform, before
/// any client is built; read by the User-Agent, the version gate and push
/// registration. Held here rather than only in a provider because the
/// network layer's base options are built outside Riverpod.
abstract final class AppVersion {
  static String _current = unknown;

  /// Until `main` has read the platform's (and in tests).
  static const String unknown = '0.0.0';

  static String get current => _current;

  /// Uses [raw] (the platform's version name) from now on.
  static void use(String raw) => _current = clean(raw);

  /// [raw] without a build number or spaces: the server reads a part that is
  /// not a plain number as 0, so `1.0.1+5` would count as 1.0.0.
  static String clean(String raw) {
    final version = raw.split('+').first.trim();
    return version.isEmpty ? unknown : version;
  }
}

/// [AppVersion.current], for widgets and features.
final appVersionProvider = Provider<String>((ref) => AppVersion.current);
