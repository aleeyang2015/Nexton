import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/clock_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../../domain/push_route.dart';
import '../../notifications_providers.dart';
import '../push_router.dart';

/// Opens the item a tapped push is about (#53). The state is the target
/// still waiting to open, if any.
///
/// A tap that started the App, or came while it was starting or stuck on the
/// forced password change, waits for a full session; it then opens once and
/// is cleared. Signed out, a tap is dropped, and a sign-out drops one
/// waiting: on a shared phone the next user never opens the last one's item.
/// One at most waits: the newest tap wins.
class PushOpenNotifier extends Notifier<PushTarget?> {
  @override
  PushTarget? build() {
    // Firebase did not start: no push, nothing to open (#51).
    if (!ref.watch(pushAvailableProvider)) return null;
    final repository = ref.watch(pushNotificationRepositoryProvider);

    final taps = repository.openedPushes.listen(
      (data) => _tapped(pushTarget(data)),
    );
    ref.onDispose(taps.cancel);

    ref.listen<AuthStatus?>(
      authSessionProvider.select((s) => s.valueOrNull?.status),
      (_, status) {
        if (status == AuthStatus.authenticated) {
          _openPending();
        } else if (status == AuthStatus.unauthenticated) {
          state = null;
        }
      },
    );

    unawaited(_launch());
    return null;
  }

  AuthStatus? get _status => ref.read(authSessionProvider).valueOrNull?.status;

  Future<void> _launch() async {
    final result = await ref
        .read(pushNotificationRepositoryProvider)
        .launchPush();
    result.when(
      success: (data) {
        if (data != null) _tapped(pushTarget(data));
      },
      failure: (failure) {
        if (kDebugMode) debugPrint('Push launch tap unread: $failure');
      },
    );
  }

  /// How close a repeat of the same tap must come to be the same tap: the
  /// banner and the tray both delivering it, or iOS reporting the launch tap
  /// twice. It opens one page, not two.
  static const Duration repeatWindow = Duration(seconds: 3);

  PushTarget? _lastTarget;
  DateTime? _lastAt;

  void _tapped(PushTarget target) {
    final now = ref.read(clockProvider)();
    final lastAt = _lastAt;
    if (target == _lastTarget &&
        lastAt != null &&
        now.difference(lastAt) < repeatWindow) {
      return;
    }
    _lastTarget = target;
    _lastAt = now;
    switch (_status) {
      case AuthStatus.unauthenticated:
        // The login screen; the push is dropped.
        state = null;
      case AuthStatus.authenticated:
        state = target;
        _openPending();
      case AuthStatus.bootstrapping || AuthStatus.mustChangePassword || null:
        state = target;
    }
  }

  void _openPending() {
    if (state == null) return;
    // After whatever is on its way now: the password page's own `go('/')`
    // after a change, or the redirect off a start screen, must not land on
    // top of the opened item.
    // A sign-out meanwhile has already cleared it.
    Timer.run(() {
      final target = state;
      if (target == null) return;
      state = null;
      ref.read(pushOpenerProvider)(target);
    });
  }
}

final pushOpenProvider = NotifierProvider<PushOpenNotifier, PushTarget?>(
  PushOpenNotifier.new,
);
