import 'dart:async';

import 'package:flutter/foundation.dart';

import '../repositories/push_notification_repository.dart';

/// Signs this phone off before a sign-out (#52, #71), so a shared phone
/// stops getting the last user's pushes.
///
/// With the session's tokens still alive ([tokensLive], a sign-out the user
/// asked for): `DELETE` the backend's row, at most [deleteLimit], then kill
/// the FCM token. A forced sign-out (the tokens already gone): the FCM token
/// only. Never throws and never holds the sign-out up for long: every
/// failure is silent (debug log only). A dead FCM token makes the server
/// drop the row itself at its next send, so a `DELETE` that failed for want
/// of signal still ends the pushes.
class SignOutThisDeviceUseCase {
  final PushNotificationRepository _repository;

  /// The longest a sign-out waits for the backend.
  final Duration deleteLimit;

  SignOutThisDeviceUseCase(
    this._repository, {
    this.deleteLimit = const Duration(seconds: 5),
  });

  Future<void> call({required bool tokensLive}) async {
    if (tokensLive) {
      try {
        final result = await _repository.unregisterDevice().timeout(
          deleteLimit,
        );
        final failure = result.failureOrNull;
        if (failure != null && kDebugMode) {
          debugPrint('[Push] sign-off failed: $failure');
        }
      } on TimeoutException {
        if (kDebugMode) debugPrint('[Push] sign-off timed out');
      }
    }
    // Not waited on: Firebase may need the network, and the sign-out must
    // not wait for it.
    unawaited(
      _repository.deleteToken().then((result) {
        final failure = result.failureOrNull;
        if (failure != null && kDebugMode) {
          debugPrint('[Push] token delete failed: $failure');
        }
      }),
    );
  }
}
