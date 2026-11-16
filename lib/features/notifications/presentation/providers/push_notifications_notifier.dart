import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../../notifications_providers.dart';

/// Keeps the backend's copy of this device's push token current, and shows
/// pushes that arrive while the app is open.
///
/// Registration needs the user's access token, so it waits for a signed-in
/// session and runs again on every sign-in — the backend then ties the device
/// to whoever is using it now. The state is the outcome of the last
/// registration attempt: true once the backend has accepted the token.
class PushNotificationsNotifier extends Notifier<bool> {
  StreamSubscription<String>? _tokenRefresh;

  @override
  bool build() {
    final repository = ref.watch(pushNotificationRepositoryProvider);

    final foreground = repository.onForegroundMessage.listen(
      repository.showForeground,
    );

    ref.listen<AuthStatus?>(
      authSessionProvider.select((session) => session.valueOrNull?.status),
      (previous, next) {
        if (next == AuthStatus.authenticated &&
            previous != AuthStatus.authenticated) {
          _startSession();
        } else if (next != AuthStatus.authenticated) {
          _stopSession();
        }
      },
      fireImmediately: true,
    );

    ref.onDispose(() {
      foreground.cancel();
      _stopSession();
    });

    return false;
  }

  void _startSession() {
    _register();
    _tokenRefresh ??= ref
        .read(pushNotificationRepositoryProvider)
        .onTokenRefresh
        .listen((_) => _register());
  }

  void _stopSession() {
    _tokenRefresh?.cancel();
    _tokenRefresh = null;
    state = false;
  }

  Future<void> _register() async {
    final result = await ref.read(registerDeviceUseCaseProvider)();
    state = result.isSuccess;

    // Not worth bothering the user over: the next sign-in or token refresh
    // tries again.
    final failure = result.failureOrNull;
    if (failure != null) debugPrint('Push registration failed: $failure');
  }
}

final pushNotificationsProvider =
    NotifierProvider<PushNotificationsNotifier, bool>(
      PushNotificationsNotifier.new,
    );
