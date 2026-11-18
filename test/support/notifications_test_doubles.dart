import 'dart:async';

import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/paged_list.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/notifications/domain/entities/app_notification.dart';
import 'package:next_on/features/notifications/domain/repositories/notifications_repository.dart';

/// The bell list's pages (#54), by hand: a page or a failure per number,
/// every page asked for recorded, and an answer that can be held.
class FakeNotificationsRepository implements NotificationsRepository {
  final Map<int, NumberedPage<AppNotification>> pages = {};
  final Map<int, Failure> failures = {};
  final List<int> asked = [];

  /// When set, the next answer waits for it.
  Completer<void>? hold;
  Completer<void>? _held;

  void release() => _held?.complete();

  @override
  FutureResult<NumberedPage<AppNotification>> notifications({
    int page = 1,
  }) async {
    asked.add(page);
    final wait = hold;
    if (wait != null) {
      _held = wait;
      await wait.future;
    }
    final failure = failures[page];
    if (failure != null) return Result.failure(failure);
    return Result.success(
      pages[page] ?? NumberedPage(items: const [], page: page, totalPages: 1),
    );
  }
}
