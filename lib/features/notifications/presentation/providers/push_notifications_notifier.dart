import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../../../../core/l10n/locale_provider.dart';
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
    // Firebase did not start: no push at all, and nothing touches it (#51).
    if (!ref.watch(pushAvailableProvider)) return false;
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

    // The App's language changed while signed in: register again, so the
    // server words pushes in it (#52).
    ref.listen(localeProvider.select((l) => l.languageCode), (previous, next) {
      if (previous != next && _signedIn) _register();
    });

    ref.onDispose(() {
      foreground.cancel();
      _stopSession();
    });

    return false;
  }

  bool _signedIn = false;

  String get _languageCode => ref.read(localeProvider).languageCode;

  void _startSession() {
    _signedIn = true;
    _register();
    // A new FCM token: `PUT` it (a server with no row for this phone gets
    // the full registration instead).
    _tokenRefresh ??= ref
        .read(pushNotificationRepositoryProvider)
        .onTokenRefresh
        .listen((_) => _updateToken());
  }

  void _stopSession() {
    _signedIn = false;
    _tokenRefresh?.cancel();
    _tokenRefresh = null;
    state = false;
  }

  Future<void> _updateToken() async {
    final result = await ref
        .read(pushNotificationRepositoryProvider)
        .updateDeviceToken(languageCode: _languageCode);
    if (result.isSuccess) state = true;
    final failure = result.failureOrNull;
    if (failure != null && kDebugMode) {
      debugPrint('Push token update failed: $failure');
    }
  }

  Future<void> _register() async {
    final result = await ref.read(registerDeviceUseCaseProvider)(
      languageCode: _languageCode,
    );
    state = result.isSuccess;

    // Not worth bothering the user over: the next sign-in or token refresh
    // tries again.
    final failure = result.failureOrNull;
    if (failure != null && kDebugMode) {
      debugPrint('Push registration failed: $failure');
    }
  }
}

final pushNotificationsProvider =
    NotifierProvider<PushNotificationsNotifier, bool>(
      PushNotificationsNotifier.new,
    );
