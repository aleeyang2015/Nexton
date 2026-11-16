import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time, as a provider.
///
/// A notifier that waits for a moment (the login throttle) reads the time
/// from here instead of calling `DateTime.now()` itself, so a test can move
/// the clock together with its fake timers.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
