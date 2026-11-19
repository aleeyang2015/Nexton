import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/features/notifications/notifications_providers.dart';
import 'package:next_on/features/notifications/presentation/providers/unread_count_notifier.dart';

import '../../support/notifications_test_doubles.dart';

/// The count on the bell (#55): when it is read, one request at a time,
/// and never a number the server did not just give.
void main() {
  late FakeNotificationsRepository repository;
  late StreamController<void> pushes;
  late ProviderContainer container;

  int? count() => container.read(unreadCountProvider);
  UnreadCountNotifier notifier() =>
      container.read(unreadCountProvider.notifier);

  setUp(() {
    repository = FakeNotificationsRepository();
    pushes = StreamController<void>.broadcast();
    container = ProviderContainer(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repository),
        foregroundPushesProvider.overrideWithValue(pushes.stream),
      ],
    );
    addTearDown(() {
      container.dispose();
      pushes.close();
    });
  });

  /// The bell shows (the user is signed in and on Home).
  Future<void> show() async {
    container.listen(unreadCountProvider, (_, _) {});
    await pumpEventQueue();
  }

  test('read when the bell first shows (after sign-in)', () async {
    repository.unreadAnswers = [3];
    expect(repository.unreadCalls, 0);

    await show();

    expect(repository.unreadCalls, 1);
    expect(count(), 3);
  });

  test('not known until the server answers: no number', () async {
    repository
      ..unreadAnswers = [3]
      ..holdUnread = Completer<void>();
    final hold = repository.holdUnread!;
    container.listen(unreadCountProvider, (_, _) {});
    await pumpEventQueue();

    expect(count(), isNull);
    hold.complete();
    await pumpEventQueue();
    expect(count(), 3);
  });

  test('a push that arrives while the App is open reads it again', () async {
    repository.unreadAnswers = [0, 1];
    await show();
    expect(count(), 0);

    pushes.add(null);
    await pumpEventQueue();

    expect(repository.unreadCalls, 2);
    expect(count(), 1);
  });

  testWidgets('the App coming back to the foreground reads it again', (
    tester,
  ) async {
    repository.unreadAnswers = [0, 2];
    await tester.runAsync(show);
    expect(count(), 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.runAsync(pumpEventQueue);

    expect(repository.unreadCalls, 2);
    expect(count(), 2);
  });

  test('one request at a time: asked again while one is on its way, it is '
      'read once more after, not twice at once', () async {
    repository.unreadAnswers = [1, 5];
    await show();
    repository.holdUnread = Completer<void>();
    final hold = repository.holdUnread!;

    final first = notifier().refresh();
    final second = notifier().refresh();
    final third = notifier().refresh();
    await pumpEventQueue();
    // Only one is out.
    expect(repository.unreadCalls, 2);

    hold.complete();
    await Future.wait([first, second, third]);
    await pumpEventQueue();

    // The one on its way, then one more for what was asked meanwhile.
    expect(repository.unreadCalls, 3);
    expect(count(), 5);
  });

  test('a failed read hides the number: never an old one shown as new',
      () async {
    repository.unreadAnswers = [
      4,
      const Failure.network(message: 'offline'),
      2,
    ];
    await show();
    expect(count(), 4);

    await notifier().refresh();
    expect(count(), isNull);

    await notifier().refresh();
    expect(count(), 2);
  });

  test('a first read that fails: no number', () async {
    repository.unreadAnswers = [const Failure.server(message: 'down')];
    await show();
    expect(count(), isNull);
  });

  test('a row just read takes one off at once; never below zero', () async {
    repository.unreadAnswers = [2];
    await show();

    notifier().oneRead();
    expect(count(), 1);
    notifier()
      ..oneRead()
      ..oneRead();
    expect(count(), 0);
  });

  test('"all read" shows zero at once', () async {
    repository.unreadAnswers = [7];
    await show();

    notifier().allRead();
    expect(count(), 0);
  });

  test('a number not known stays not known when a row is read', () async {
    repository.unreadAnswers = [const Failure.server(message: 'down')];
    await show();

    notifier().oneRead();
    expect(count(), isNull);
  });

  test('gone with the bell (a sign-out): nothing is kept for the next '
      'user, and a late answer changes nothing', () async {
    repository.unreadAnswers = [9];
    final sub = container.listen(unreadCountProvider, (_, _) {});
    await pumpEventQueue();
    expect(count(), 9);
    repository.holdUnread = Completer<void>();
    final hold = repository.holdUnread!;
    final late = notifier().refresh();

    sub.close();
    await pumpEventQueue();
    hold.complete();
    await late;

    // Built again for the next user: read again, from nothing.
    repository.unreadAnswers = [1];
    repository.unreadCalls = 0;
    container.listen(unreadCountProvider, (_, _) {});
    expect(count(), isNull);
    await pumpEventQueue();
    expect(count(), 1);
  });
}
