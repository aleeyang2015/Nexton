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

  // --- Read and unread (#55) ---

  /// What `unreadCount()` answers, one per call; the last one is repeated.
  /// A [Failure] in the list is a failed call.
  List<Object> unreadAnswers = [0];
  int unreadCalls = 0;

  /// When set, the next `unreadCount()` waits for it.
  Completer<void>? holdUnread;

  final List<String> markedRead = [];
  int markAllCalls = 0;

  /// When set, `markRead` and `markAllRead` fail with it.
  Failure? markFailure;

  /// When set, the next `markRead` or `markAllRead` waits for it.
  Completer<void>? holdMark;

  @override
  FutureResult<int> unreadCount() async {
    final index = unreadCalls < unreadAnswers.length
        ? unreadCalls
        : unreadAnswers.length - 1;
    final answer = unreadAnswers[index];
    unreadCalls++;
    final wait = holdUnread;
    holdUnread = null;
    await wait?.future;
    return answer is Failure ? Result.failure(answer) : Result.success(answer as int);
  }

  @override
  FutureResult<Unit> markRead(String id) async {
    markedRead.add(id);
    final wait = holdMark;
    holdMark = null;
    await wait?.future;
    final failure = markFailure;
    return failure == null
        ? const Result.success(Unit.instance)
        : Result.failure(failure);
  }

  @override
  FutureResult<Unit> markAllRead() async {
    markAllCalls++;
    final wait = holdMark;
    holdMark = null;
    await wait?.future;
    final failure = markFailure;
    return failure == null
        ? const Result.success(Unit.instance)
        : Result.failure(failure);
  }
}
