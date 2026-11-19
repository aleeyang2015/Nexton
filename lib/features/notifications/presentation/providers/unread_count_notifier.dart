import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications_providers.dart';

/// How many rows of the bell list are unread (#55): the number on the bell.
/// Null while it is not known: before the first answer, and after a read
/// that failed. A number is only ever one the server just gave (or that
/// number less what the user has read since), never an old one kept alive.
///
/// Read when the bell first shows (after sign-in), when the App comes back
/// to the foreground, when a push arrives while the App is open, and after
/// rows are marked read. One request at a time, and no timer.
///
/// AutoDispose: it lives with the bell on Home, so a sign-out drops it and
/// the next user starts from nothing.
class UnreadCountNotifier extends AutoDisposeNotifier<int?> {
  bool _disposed = false;

  /// The read on its way, if any.
  Future<void>? _reading;

  /// Asked again while a read was on its way: read once more after it.
  bool _again = false;

  @override
  int? build() {
    _disposed = false;
    _reading = null;
    _again = false;
    _marking = 0;

    final pushes = ref
        .watch(foregroundPushesProvider)
        .listen((_) => unawaited(refresh()), onError: (_) {});
    final lifecycle = _tryCreateLifecycleListener();
    ref.onDispose(() {
      _disposed = true;
      pushes.cancel();
      lifecycle?.dispose();
    });

    Future.microtask(refresh);
    return null;
  }

  /// A plain container (a test) has no binding to listen to.
  AppLifecycleListener? _tryCreateLifecycleListener() {
    try {
      return AppLifecycleListener(onResume: () => unawaited(refresh()));
    } catch (_) {
      return null;
    }
  }

  /// Reads the count from the server. While a read is on its way, this
  /// only notes that one more is wanted after it: whatever changed in the
  /// meantime is then counted, with never two requests out at once.
  Future<void> refresh() {
    if (_disposed) return Future.value();
    final reading = _reading;
    if (reading != null) {
      _again = true;
      return reading;
    }
    return _reading = _read().whenComplete(() {
      _reading = null;
      // Asked in the instant between the last answer and now.
      if (_again && !_disposed) unawaited(refresh());
    });
  }

  Future<void> _read() async {
    do {
      _again = false;
      int? count;
      try {
        count = (await ref.read(getUnreadCountUseCaseProvider)()).dataOrNull;
      } catch (_) {
        // The bell never breaks the screen it sits on: no number.
        count = null;
      }
      if (_disposed) return;
      // The user is marking rows read and the server may not know yet:
      // this answer could be the number from before. [markSettled] reads
      // again once the server has been told.
      if (_marking > 0) continue;
      // A failure hides the number: an old one would pass for a fresh one.
      state = count;
    } while (_again);
  }

  /// Marks the server is being told about and has not answered yet.
  int _marking = 0;

  /// The user has just read one row: one less, at once. Until
  /// [markSettled], no answer from the server replaces it.
  void oneRead() {
    _marking++;
    final count = state;
    if (count != null && count > 0) state = count - 1;
  }

  /// The user has just marked everything read: zero, at once. Until
  /// [markSettled], no answer from the server replaces it.
  void allRead() {
    _marking++;
    if (state != null) state = 0;
  }

  /// The server has answered a mark started with [oneRead] or [allRead]
  /// (or the call failed): its own count is read again, so the number shown
  /// is the server's, whether the mark went through or not.
  Future<void> markSettled() {
    if (_marking > 0) _marking--;
    return refresh();
  }
}

final unreadCountProvider =
    NotifierProvider.autoDispose<UnreadCountNotifier, int?>(
      UnreadCountNotifier.new,
    );
