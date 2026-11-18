import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../domain/usecases/sign_out_this_device_usecase.dart';
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
      if (previous != next && _signedIn) _track(_register());
    });

    ref.onDispose(() {
      foreground.cancel();
      _stopSession();
    });

    return false;
  }

  bool _signedIn = false;

  String get _languageCode => ref.read(localeProvider).languageCode;

  /// The registration call on its way, if any: a sign-out waits for it,
  /// so it cannot land after the `DELETE` and turn the row back on.
  Future<void>? _inFlight;

  void _track(Future<void> call) {
    _inFlight = call;
    call.whenComplete(() {
      if (identical(_inFlight, call)) _inFlight = null;
    });
  }

  /// Before a sign-out signs this phone off (#52): no new registration, and
  /// the one on its way (if any) has landed, at most [limit].
  Future<void> stopForSignOut({
    Duration limit = const Duration(seconds: 3),
  }) async {
    _stopSession();
    final inFlight = _inFlight;
    if (inFlight == null) return;
    try {
      await inFlight.timeout(limit);
    } catch (_) {
      // Never holds a sign-out up.
    }
  }

  void _startSession() {
    _signedIn = true;
    _track(_register());
    // A new FCM token: `PUT` it (a server with no row for this phone gets
    // the full registration instead).
    _tokenRefresh ??= ref
        .read(pushNotificationRepositoryProvider)
        .onTokenRefresh
        .listen((_) => _track(_updateToken()));
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

/// Signs this phone off before a sign-out (#52): the push session stops and
/// a registration on its way lands first, then the backend's row and the
/// FCM token go. Nothing at all when Firebase did not start. Wired into
/// auth's `beforeSignOutProvider` in `main.dart`, so auth needs no import of
/// this feature.
final signOutThisDeviceProvider =
    Provider<Future<void> Function({required bool tokensLive})>((ref) {
      if (!ref.watch(pushAvailableProvider)) {
        return ({required bool tokensLive}) async {};
      }
      final useCase = SignOutThisDeviceUseCase(
        ref.watch(pushNotificationRepositoryProvider),
      );
      return ({required bool tokensLive}) async {
        await ref.read(pushNotificationsProvider.notifier).stopForSignOut();
        await useCase(tokensLive: tokensLive);
      };
    });
