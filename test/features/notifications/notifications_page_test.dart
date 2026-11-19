import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/paged_list.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/auth/auth_providers.dart';
import 'package:next_on/features/home/presentation/widgets/home_header.dart';
import 'package:next_on/features/notifications/domain/entities/app_notification.dart';
import 'package:next_on/features/notifications/domain/push_route.dart';
import 'package:next_on/features/notifications/notifications_providers.dart';
import 'package:next_on/features/notifications/presentation/pages/notifications_page.dart';
import 'package:next_on/features/notifications/presentation/push_router.dart';
import 'package:next_on/features/profile/presentation/pages/profile_page.dart';
import 'package:next_on/features/profile/profile_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/attendance_test_doubles.dart';
import '../../support/auth_test_doubles.dart';
import '../../support/notifications_test_doubles.dart';
import '../../support/profile_test_doubles.dart';
import '../../support/test_asset_bundle.dart';

/// The bell list's screen (#54), and the two ways in: the bell on Home and
/// Profile → Notifications.
void main() {
  final en = AppLocalizationsEn();
  late FakeNotificationsRepository repository;
  late List<PushTarget> opened;

  AppNotification row(
    String id, {
    String type = 'leave_request',
    Map<String, String> data = const {
      'reference_type': 'leave_request',
      'reference_id': 'lr-1',
    },
    NotificationSendStatus status = NotificationSendStatus.sent,
    bool isRead = true,
  }) => AppNotification(
    id: id,
    type: type,
    title: 'Title $id',
    body: 'Body $id',
    data: data,
    status: status,
    isRead: isRead,
    createdAt: DateTime(2026, 11, 18, 14, 5),
  );

  setUp(() {
    repository = FakeNotificationsRepository();
    opened = [];
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
          pushOpenerProvider.overrideWithValue((t) async => opened.add(t)),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const NotificationsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('no rows: "No notifications yet"', (tester) async {
    await pumpPage(tester);
    expect(find.text(en.notificationsEmpty), findsOneWidget);
  });

  testWidgets('a failed load: the error with Retry, and Retry works', (
    tester,
  ) async {
    repository.failures[1] = const Failure.server(message: 'down');
    await pumpPage(tester);
    expect(find.text(en.notificationsLoadFailed), findsOneWidget);

    repository.failures.remove(1);
    repository.pages[1] = NumberedPage(
      items: [row('a')],
      page: 1,
      totalPages: 1,
    );
    await tester.tap(find.text(en.retry));
    await tester.pumpAndSettle();
    expect(find.text('Title a'), findsOneWidget);
  });

  testWidgets('a row: its kind, the server\'s words as sent, and when; a '
      'failed send still shows', (tester) async {
    repository.pages[1] = NumberedPage(
      items: [
        row('a'),
        row(
          'b',
          type: 'overtime_request',
          status: NotificationSendStatus.failed,
          data: const {
            'reference_type': 'overtime_request',
            'reference_id': 'ot-1',
          },
        ),
      ],
      page: 1,
      totalPages: 1,
    );
    await pumpPage(tester);

    expect(find.text(en.leaveMenu), findsOneWidget);
    expect(find.text(en.otMenu), findsOneWidget);
    expect(find.text('Title a'), findsOneWidget);
    expect(find.text('Body a'), findsOneWidget);
    expect(find.text('Title b'), findsOneWidget);
    expect(find.text('18 Nov 2026 14:05'), findsNWidgets(2));
  });

  testWidgets('tapping a leave row opens that request; an off-site row opens '
      'Home', (tester) async {
    repository.pages[1] = NumberedPage(
      items: [
        row('a'),
        row(
          'b',
          type: 'attendance_offsite',
          data: const {'reference_type': 'attendance'},
        ),
      ],
      page: 1,
      totalPages: 1,
    );
    await pumpPage(tester);

    await tester.tap(find.text('Title a'));
    await tester.tap(find.text('Title b'));
    expect(opened, [const LeaveRequestTarget('lr-1'), const HomeTarget()]);
  });

  testWidgets('two quick taps on a row open one page', (tester) async {
    repository.pages[1] = NumberedPage(
      items: [row('a')],
      page: 1,
      totalPages: 1,
    );
    final closing = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
          pushOpenerProvider.overrideWithValue((t) {
            opened.add(t);
            // The opened page stays until it is closed.
            return closing.future;
          }),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const NotificationsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Title a'));
    await tester.tap(find.text('Title a'));
    expect(opened, hasLength(1));

    // Back on the list: a tap opens it again.
    closing.complete();
    await tester.pump();
    await tester.tap(find.text('Title a'));
    expect(opened, hasLength(2));
  });

  testWidgets('any OT kind, today\'s or a new one, is labelled OT', (
    tester,
  ) async {
    repository.pages[1] = NumberedPage(
      items: [row('a', type: 'overtime_reminder', data: const {})],
      page: 1,
      totalPages: 1,
    );
    await pumpPage(tester);
    expect(find.text(en.otMenu), findsOneWidget);
  });

  testWidgets('a row with nowhere of its own to open does nothing', (
    tester,
  ) async {
    repository.pages[1] = NumberedPage(
      items: [row('a', type: 'payslip_ready', data: const {})],
      page: 1,
      totalPages: 1,
    );
    await pumpPage(tester);
    await tester.tap(find.text('Title a'));
    expect(opened, isEmpty);
  });

  group('read and unread (#55)', () {
    Finder dot(String id) => find.byKey(ValueKey('notification-unread-$id'));

    void rows(List<AppNotification> items) => repository.pages[1] =
        NumberedPage(items: items, page: 1, totalPages: 1);

    testWidgets('a dot on each unread row, none on a read one', (tester) async {
      rows([row('a', isRead: false), row('b')]);
      repository.unreadAnswers = [1];
      await pumpPage(tester);

      expect(dot('a'), findsOneWidget);
      expect(dot('b'), findsNothing);
    });

    testWidgets('tapping an unread row marks it read and opens it, without '
        'waiting for the server', (tester) async {
      rows([row('a', isRead: false)]);
      repository
        ..unreadAnswers = [1, 0]
        ..holdMark = Completer<void>();
      final hold = repository.holdMark!;
      await pumpPage(tester);

      await tester.tap(find.text('Title a'));
      await tester.pump();

      // Opened and shown as read while the mark-read call is still out.
      expect(opened, [const LeaveRequestTarget('lr-1')]);
      expect(repository.markedRead, ['a']);
      expect(dot('a'), findsNothing);

      hold.complete();
      await tester.pumpAndSettle();
      expect(dot('a'), findsNothing);
    });

    testWidgets('a second row tapped while the first one\'s page is opening '
        'is neither opened nor marked read', (tester) async {
      rows([row('a', isRead: false), row('b', isRead: false)]);
      repository.unreadAnswers = [2];
      final closing = Completer<void>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsRepositoryProvider.overrideWithValue(repository),
            pushOpenerProvider.overrideWithValue((t) {
              opened.add(t);
              return closing.future;
            }),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const NotificationsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Title a'));
      await tester.tap(find.text('Title b'));
      await tester.pump();

      expect(opened, hasLength(1));
      expect(repository.markedRead, ['a']);
      expect(dot('b'), findsOneWidget);
      closing.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('tapping a row already read marks nothing', (tester) async {
      rows([row('a')]);
      await pumpPage(tester);

      await tester.tap(find.text('Title a'));
      await tester.pump();

      expect(opened, hasLength(1));
      expect(repository.markedRead, isEmpty);
    });

    testWidgets('an unread row with nowhere to open is still marked read by '
        'a tap', (tester) async {
      rows([row('a', type: 'payslip_ready', data: const {}, isRead: false)]);
      repository.unreadAnswers = [1, 0];
      await pumpPage(tester);

      await tester.tap(find.text('Title a'));
      await tester.pumpAndSettle();

      expect(opened, isEmpty);
      expect(repository.markedRead, ['a']);
      expect(dot('a'), findsNothing);
    });

    testWidgets('mark-read fails: the row stays shown as read here, and no '
        'error is shown', (tester) async {
      rows([row('a', isRead: false)]);
      repository
        ..unreadAnswers = [1]
        ..markFailure = const Failure.network(message: 'offline');
      await pumpPage(tester);

      await tester.tap(find.text('Title a'));
      await tester.pumpAndSettle();

      expect(dot('a'), findsNothing);
      expect(find.text(en.notificationsLoadFailed), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('"Mark all as read" shows only while something is unread', (
      tester,
    ) async {
      rows([row('a')]);
      repository.unreadAnswers = [0];
      await pumpPage(tester);
      expect(find.text(en.notificationsMarkAllRead), findsNothing);
    });

    testWidgets('"Mark all as read" hidden when the count is not known', (
      tester,
    ) async {
      rows([row('a', isRead: false)]);
      repository.unreadAnswers = [const Failure.server(message: 'down')];
      await pumpPage(tester);
      expect(find.text(en.notificationsMarkAllRead), findsNothing);
    });

    testWidgets('"Mark all as read": every dot goes, the button goes, one '
        'call even on a double tap', (tester) async {
      rows([row('a', isRead: false), row('b', isRead: false), row('c')]);
      // Read when the page opens and again when its list has loaded; then
      // after "mark all".
      repository.unreadAnswers = [2, 2, 0];
      await pumpPage(tester);
      expect(find.text(en.notificationsMarkAllRead), findsOneWidget);
      repository.holdMark = Completer<void>();
      final hold = repository.holdMark!;

      await tester.tap(find.text(en.notificationsMarkAllRead));
      await tester.pump();
      // Shown as read at once.
      expect(dot('a'), findsNothing);
      expect(dot('b'), findsNothing);
      expect(find.text(en.notificationsMarkAllRead), findsNothing);

      hold.complete();
      await tester.pumpAndSettle();
      expect(repository.markAllCalls, 1);
      expect(dot('a'), findsNothing);
      expect(find.text(en.notificationsMarkAllRead), findsNothing);
    });
  });

  group('the count on the bell (#55)', () {
    Future<void> pumpBell(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(
              FakeProfileRepository(),
            ),
            notificationsRepositoryProvider.overrideWithValue(repository),
          ],
          child: DefaultAssetBundle(
            bundle: TestAssetBundle(),
            child: MaterialApp(
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const Scaffold(body: HomeHeader()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('unread rows: the number, and it is read out', (tester) async {
      repository.unreadAnswers = [3];
      await pumpBell(tester);

      expect(find.text('3'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          '${en.notifications}, ${en.notificationsUnreadCount(3)}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('nothing unread: no number', (tester) async {
      repository.unreadAnswers = [0];
      await pumpBell(tester);

      expect(find.text('0'), findsNothing);
      expect(find.bySemanticsLabel(en.notifications), findsOneWidget);
    });

    testWidgets('more than 99: "99+"', (tester) async {
      repository.unreadAnswers = [120];
      await pumpBell(tester);
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('the count cannot be read: no number, not an old one', (
      tester,
    ) async {
      repository.unreadAnswers = [const Failure.server(message: 'down')];
      await pumpBell(tester);

      expect(find.byKey(const ValueKey('bell-unread-count')), findsNothing);
      expect(find.bySemanticsLabel(en.notifications), findsOneWidget);
    });
  });

  group('the ways in', () {
    late GoRouter router;

    Widget app(Widget home, List<Override> overrides) {
      router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => home),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (_, _) => const Text('BELL LIST'),
          ),
        ],
      );
      return ProviderScope(
        overrides: overrides,
        child: DefaultAssetBundle(
          bundle: TestAssetBundle(),
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
    }

    testWidgets('the bell on Home', (tester) async {
      tester.view.physicalSize = const Size(390, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(const Scaffold(body: HomeHeader()), [
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        ]),
      );
      await tester.pump();
      await tester.pump();

      expect(find.bySemanticsLabel(en.notifications), findsOneWidget);
      await tester.tap(find.byTooltip(en.notifications));
      await tester.pumpAndSettle();
      expect(find.text('BELL LIST'), findsOneWidget);
    });

    testWidgets('Profile → Notifications', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final auth = FakeAuthRepository();
      addTearDown(auth.sessionExpired.close);
      await tester.pumpWidget(
        app(const ProfilePage(), [
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          attendanceRepositoryProvider.overrideWithValue(
            FakeAttendanceRepository(),
          ),
          authRepositoryProvider.overrideWithValue(auth),
        ]),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text(en.notifications));
      await tester.pumpAndSettle();
      expect(find.text('BELL LIST'), findsOneWidget);
    });
  });

  group('a push for the bell list (#53\'s opener)', () {
    late GoRouter router;

    Future<ProviderContainer> start(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('HOME')),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (_, _) => const NotificationsPage(),
          ),
          GoRoute(
            path: '/detail',
            builder: (_, _) => const Scaffold(body: Text('DETAIL')),
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
          appRouterProvider.overrideWithValue(router),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('the list already on top: read again, not pushed over itself', (
      tester,
    ) async {
      final container = await start(tester);
      unawaited(router.push(AppRoutes.notifications));
      await tester.pumpAndSettle();
      expect(repository.asked, [1]);

      unawaited(
        container.read(pushOpenerProvider)(const NotificationsTarget()),
      );
      await tester.pumpAndSettle();

      expect(repository.asked, [1, 1]);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('the list open under another page: the list on top shows the '
        'rows read again', (tester) async {
      final container = await start(tester);
      repository.pages[1] = NumberedPage(
        items: [row('old')],
        page: 1,
        totalPages: 1,
      );
      unawaited(router.push(AppRoutes.notifications));
      await tester.pumpAndSettle();
      unawaited(router.push('/detail'));
      await tester.pumpAndSettle();

      repository.pages[1] = NumberedPage(
        items: [row('new'), row('old')],
        page: 1,
        totalPages: 1,
      );
      unawaited(
        container.read(pushOpenerProvider)(const NotificationsTarget()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Title new'), findsOneWidget);
    });
  });
}
