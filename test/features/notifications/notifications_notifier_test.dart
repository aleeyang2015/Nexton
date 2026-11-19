import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/paged_list.dart';
import 'package:next_on/features/notifications/domain/entities/app_notification.dart';
import 'package:next_on/features/notifications/notifications_providers.dart';
import 'package:next_on/features/notifications/presentation/providers/notifications_notifier.dart';
import 'package:next_on/features/notifications/presentation/providers/unread_count_notifier.dart';

import '../../support/notifications_test_doubles.dart';

/// The bell list (#54): page by page, refresh, errors and Retry, and a
/// list that never outlives its screen (a sign-out drops it).
void main() {
  late FakeNotificationsRepository repository;
  late ProviderContainer container;
  late ProviderSubscription<NotificationsState> sub;

  NotificationsState state() => container.read(notificationsNotifierProvider);
  NotificationsNotifier notifier() =>
      container.read(notificationsNotifierProvider.notifier);
  List<String> shown() => [for (final r in state().visible) r.id];

  setUp(() {
    repository = FakeNotificationsRepository();
    container = ProviderContainer(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  /// Opens the list (the screen shows), once the pages are set.
  Future<void> open() async {
    sub = container.listen(notificationsNotifierProvider, (_, _) {});
    await pumpEventQueue();
  }

  tearDown(() => container.dispose());

  test('opens on page 1', () async {
    repository.pages[1] = page(1, 2, ['a', 'b']);
    await open();
    expect(repository.asked, [1]);
    expect(shown(), ['a', 'b']);
    expect(state().rows.valueOrNull!.hasMore, isTrue);
  });

  test('load more: page 2 once, even when asked twice; no row skipped or '
      'shown twice', () async {
    repository.pages[1] = page(1, 2, ['a', 'b']);
    // Page 2 repeats "b": a row added at the top shifted the pages.
    repository.pages[2] = page(2, 2, ['b', 'c']);
    await open();
    repository.hold = Completer<void>();

    final first = notifier().loadMore();
    final second = notifier().loadMore();
    repository.hold!.complete();
    await Future.wait([first, second]);

    expect(repository.asked, [1, 2]);
    expect(
      [for (final r in state().rows.valueOrNull!.items) r.id],
      ['a', 'b', 'c'],
    );
    expect(shown(), ['a', 'b', 'c']);
    expect(state().rows.valueOrNull!.hasMore, isFalse);

    await notifier().loadMore();
    expect(repository.asked, [1, 2]);
  });

  test('a two-phone pair split across two pages shows once', () async {
    repository.pages[1] = page(1, 2, ['a'], sameSendAs: 'x');
    repository.pages[2] = page(2, 2, ['b'], sameSendAs: 'x');
    await open();
    await notifier().loadMore();
    expect(shown(), ['a']);
    expect(state().rows.valueOrNull!.items, hasLength(2));
  });

  test('the first page fails: the error, then Retry loads it', () async {
    repository.failures[1] = const Failure.server(message: 'down');
    await open();
    expect(state().rows.hasError, isTrue);

    repository.failures.remove(1);
    repository.pages[1] = page(1, 1, ['a']);
    notifier().retry();
    await pumpEventQueue();
    expect(shown(), ['a']);
  });

  test('429 (a network failure here) shows the error, with Retry', () async {
    repository.failures[1] = const Failure.network(
      message: 'Too many requests',
      statusCode: 429,
      retryAfter: Duration(seconds: 30),
    );
    await open();
    expect(state().rows.hasError, isTrue);
    expect(state().rows.error, isA<Failure>());
  });

  test('a next page fails: the rows stay, Retry asks again', () async {
    repository.pages[1] = page(1, 2, ['a']);
    await open();
    repository.failures[2] = const Failure.network(message: 'offline');
    await notifier().loadMore();
    expect(shown(), ['a']);
    expect(state().rows.valueOrNull!.loadMoreError, isNotNull);

    // No retry by scrolling: only the Retry button.
    await notifier().loadMore();
    expect(repository.asked, [1, 2]);

    repository.failures.remove(2);
    repository.pages[2] = page(2, 2, ['b']);
    await notifier().retryLoadMore();
    expect(repository.asked, [1, 2, 2]);
    expect(shown(), ['a', 'b']);
  });

  test(
    'pull to refresh: page 1 again; a refresh that fails keeps the rows',
    () async {
      repository.pages[1] = page(1, 1, ['a']);
      await open();

      repository.pages[1] = page(1, 1, ['new', 'a']);
      expect(await notifier().refresh(), isTrue);
      expect(shown(), ['new', 'a']);

      repository.failures[1] = const Failure.network(message: 'offline');
      expect(await notifier().refresh(), isFalse);
      expect(shown(), ['new', 'a']);
      expect(state().rows.isLoading, isFalse);
      expect(state().rows.hasError, isFalse);
    },
  );

  test('a page 2 that lands after a refresh is dropped', () async {
    repository.pages[1] = page(1, 2, ['a']);
    repository.pages[2] = page(2, 2, ['old']);
    await open();
    repository.hold = Completer<void>();
    final more = notifier().loadMore();
    await pumpEventQueue();
    repository.hold = null;
    repository.pages[1] = page(1, 1, ['fresh']);
    await notifier().refresh();
    // Page 2 answers now, for the list that is gone.
    repository.release();
    await more;
    expect(shown(), ['fresh']);
  });

  test('closed (the screen left, or a sign-out): the rows go; opened again, '
      'they are read again', () async {
    repository.pages[1] = page(1, 1, ['first-user']);
    await open();
    expect(shown(), ['first-user']);

    sub.close();
    await pumpEventQueue();
    repository.pages[1] = page(1, 1, ['second-user']);
    sub = container.listen(notificationsNotifierProvider, (_, _) {});
    expect(state().rows.isLoading, isTrue);
    expect(state().visible, isEmpty);
    await pumpEventQueue();
    expect(shown(), ['second-user']);
  });
  group('rows read here stay read, whatever list answer lands after (#55)',
      () {
    List<String> unreadShown() => [
      for (final r in state().visible)
        if (!r.isRead) r.id,
    ];

    test('a row read while the next page is on its way stays read when it '
        'lands', () async {
      repository.pages[1] = page(1, 2, ['a', 'b'], unread: {'a', 'b'});
      repository.pages[2] = page(2, 2, ['c'], unread: {'c'});
      await open();
      repository.hold = Completer<void>();
      final more = notifier().loadMore();

      await notifier().markRead('a');
      repository.release();
      await more;

      expect(shown(), ['a', 'b', 'c']);
      expect(unreadShown(), ['b', 'c']);
    });

    test('a row read while the next page is on its way stays read when that '
        'page fails', () async {
      repository.pages[1] = page(1, 2, ['a', 'b'], unread: {'a', 'b'});
      repository.failures[2] = const Failure.network(message: 'offline');
      await open();
      repository.hold = Completer<void>();
      final more = notifier().loadMore();

      await notifier().markRead('a');
      repository.release();
      await more;

      expect(unreadShown(), ['b']);
    });

    test('"mark all" answered before the next page lands: that page\'s rows '
        'are read too (they were there when all was marked)', () async {
      repository.pages[1] = page(1, 2, ['a', 'b'], unread: {'a', 'b'});
      repository.pages[2] = page(2, 2, ['c'], unread: {'c'});
      await open();
      repository.hold = Completer<void>();
      final more = notifier().loadMore();

      await notifier().markAllRead();
      repository.release();
      await more;

      expect(shown(), ['a', 'b', 'c']);
      expect(unreadShown(), isEmpty);
    });

    test('a row read while a refresh is on its way stays read when the '
        'refresh fails, and the refresh still shows as one meanwhile',
        () async {
      repository.pages[1] = page(1, 1, ['a', 'b'], unread: {'a', 'b'});
      await open();
      repository
        ..failures[1] = const Failure.network(message: 'offline')
        ..hold = Completer<void>();
      final refresh = notifier().refresh();

      await notifier().markRead('a');
      expect(state().rows.isLoading, isTrue);
      repository.release();
      expect(await refresh, isFalse);

      expect(unreadShown(), ['b']);
    });

    test('a refresh answered with the server\'s older truth does not bring '
        'the dot back; a row new in that answer is still unread', () async {
      repository.pages[1] = page(1, 1, ['a', 'b'], unread: {'a', 'b'});
      await open();
      repository.hold = Completer<void>();
      final refresh = notifier().refresh();

      await notifier().markRead('a');
      // What the server had before the mark reached it, plus a new row.
      repository.pages[1] = page(1, 1, ['n', 'a', 'b'], unread: {'n', 'a', 'b'});
      repository.release();
      await refresh;

      expect(unreadShown(), ['n', 'b']);
    });

    test('after "mark all", a later refresh shows what is new as unread',
        () async {
      repository.pages[1] = page(1, 1, ['a'], unread: {'a'});
      await open();
      await notifier().markAllRead();

      repository.pages[1] = page(1, 1, ['n', 'a'], unread: {'n'});
      await notifier().refresh();

      expect(unreadShown(), ['n']);
    });

    test('"mark all" fails: the rows stay shown as read', () async {
      repository.pages[1] = page(1, 1, ['a', 'b'], unread: {'a', 'b'});
      await open();
      repository.markFailure = const Failure.network(message: 'offline');

      await notifier().markAllRead();

      expect(unreadShown(), isEmpty);
      expect(state().rows.hasError, isFalse);
    });

    test('two unread rows that say the same are both shown: an unread row '
        'is never hidden as a copy', () async {
      repository.pages[1] = page(
        1,
        1,
        ['a', 'b'],
        sameSendAs: 'Same',
        unread: {'a', 'b'},
      );
      await open();

      expect(shown(), ['a', 'b']);
    });
  });

  group('the bell\'s count follows the list (#55)', () {
    late ProviderContainer c;

    int? count() => c.read(unreadCountProvider);

    Future<void> openWithBell() async {
      c = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
          foregroundPushesProvider.overrideWithValue(const Stream.empty()),
        ],
      );
      addTearDown(c.dispose);
      // The bell on Home, under the list.
      c.listen(unreadCountProvider, (_, _) {});
      await pumpEventQueue();
    }

    test('a successful list load reads the count again', () async {
      repository.unreadAnswers = [0, 2];
      await openWithBell();
      expect(count(), 0);

      c.listen(notificationsNotifierProvider, (_, _) {});
      await pumpEventQueue();

      expect(count(), 2);
    });

    test('a row read: one less at once, then the server\'s number once the '
        'mark has answered; an answer that was already on its way is not '
        'shown in between', () async {
      repository.pages[1] = page(1, 1, ['a', 'b'], unread: {'a', 'b'});
      repository.unreadAnswers = [2, 2, 2, 1];
      await openWithBell();
      c.listen(notificationsNotifierProvider, (_, _) {});
      await pumpEventQueue();
      expect(count(), 2);

      // A count read is out (it will say 2) when the row is tapped.
      repository.holdUnread = Completer<void>();
      final staleHold = repository.holdUnread!;
      final stale = c.read(unreadCountProvider.notifier).refresh();
      repository.holdMark = Completer<void>();
      final markHold = repository.holdMark!;
      final marking = c
          .read(notificationsNotifierProvider.notifier)
          .markRead('a');
      expect(count(), 1);

      staleHold.complete();
      await pumpEventQueue();
      // Still the user's own 1, not the 2 asked for before the tap.
      expect(count(), 1);

      markHold.complete();
      await marking;
      await stale;
      await pumpEventQueue();
      expect(count(), 1);
      expect(repository.unreadCalls, 4);
    });

    test('the list is left before the mark answers, and the mark fails: the '
        'count is still read again, so the bell does not keep a number the '
        'server never gave', () async {
      repository.pages[1] = page(1, 1, ['a'], unread: {'a'});
      repository.unreadAnswers = [1, 1, 1];
      await openWithBell();
      final list = c.listen(notificationsNotifierProvider, (_, _) {});
      await pumpEventQueue();
      repository
        ..markFailure = const Failure.network(message: 'offline')
        ..holdMark = Completer<void>();
      final hold = repository.holdMark!;

      final marking = c
          .read(notificationsNotifierProvider.notifier)
          .markRead('a');
      expect(count(), 0);
      // Back to Home: the list goes.
      list.close();
      await pumpEventQueue();
      hold.complete();
      await marking;
      await pumpEventQueue();

      expect(count(), 1);
    });
  });
}

NumberedPage<AppNotification> page(
  int number,
  int total,
  List<String> ids, {
  String? sameSendAs,
  Set<String> unread = const {},
}) => NumberedPage(
  page: number,
  totalPages: total,
  items: [
    for (final (i, id) in ids.indexed)
      AppNotification(
        id: id,
        type: 'leave_request',
        title: sameSendAs ?? 'Title $id',
        body: 'Body',
        data: const {},
        status: NotificationSendStatus.sent,
        isRead: !unread.contains(id),
        createdAt: DateTime.utc(
          2026,
          11,
          18,
          9,
        ).subtract(Duration(seconds: number * 10 + i)),
      ),
  ],
);
