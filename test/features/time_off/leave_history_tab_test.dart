import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/paged_list.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/time_off/domain/entities/leave_history_query.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_history_tab.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';

import '../../support/leave_test_doubles.dart';

/// The history tab loads a page of 20 and fetches the next as the user
/// nears the end of the list.
void main() {
  final en = AppLocalizationsEn();
  late FakeLeaveRepository repository;
  late bool down;

  List<LeaveRequest> rows(int from, int count) => [
    for (var i = from; i < from + count; i++)
      sampleLeaveRequest(id: 'r-$i', reason: 'request $i'),
  ];

  FutureResult<CursorPage<LeaveRequest>> pages(
    LeaveHistoryQuery query,
    String? cursor,
  ) async {
    if (cursor != null && down) {
      return const Result.failure(Failure.network(message: 'offline'));
    }
    return Result.success(switch (cursor) {
      null => CursorPage(items: rows(0, 20), nextCursor: 'c-2', hasMore: true),
      'c-2' => CursorPage(items: rows(20, 5)),
      _ => const CursorPage(items: []),
    });
  }

  setUp(() {
    down = false;
    repository = FakeLeaveRepository()..myRequestsPage = pages;
  });

  Future<void> pumpTab(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [leaveRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: LeaveHistoryTab()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  Future<void> scrollToEnd(WidgetTester tester) async {
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('opens with the first page only', (tester) async {
    await pumpTab(tester);

    expect(repository.myRequestsCursors, [null]);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('scrolling near the end loads the next page, once', (
    tester,
  ) async {
    await pumpTab(tester);

    await scrollToEnd(tester);

    expect(repository.myRequestsCursors, [null, 'c-2']);

    // At the very end now, and there is no more: nothing else is asked for.
    await scrollToEnd(tester);
    expect(repository.myRequestsCursors, [null, 'c-2']);
    expect(find.text(en.listLoadMoreFailed), findsNothing);
  });

  testWidgets('scrolling a little, far from the end, loads nothing', (
    tester,
  ) async {
    await pumpTab(tester);

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    position.jumpTo(200);
    await tester.pump();

    expect(repository.myRequestsCursors, [null]);
  });

  testWidgets('with the network off for a later page: the rows stay, '
      '"could not load more" and Retry show, and Retry continues', (
    tester,
  ) async {
    await pumpTab(tester);
    down = true;

    await scrollToEnd(tester);
    await scrollToEnd(tester);

    expect(find.text(en.listLoadMoreFailed), findsOneWidget);
    expect(find.text(en.leaveHistoryLoadFailed), findsNothing);
    // Scrolling again did not ask again.
    expect(repository.myRequestsCursors, [null, 'c-2']);

    down = false;
    await tester.tap(find.text(en.retry));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(repository.myRequestsCursors, [null, 'c-2', 'c-2']);
    expect(find.text(en.listLoadMoreFailed), findsNothing);
  });

  testWidgets('a first page that fails shows the whole-list error, as '
      'before', (tester) async {
    repository.myRequestsPage = (_, _) async =>
        const Result.failure(Failure.network(message: 'offline'));

    await pumpTab(tester);

    expect(find.text(en.leaveHistoryLoadFailed), findsOneWidget);
    expect(find.text(en.listLoadMoreFailed), findsNothing);
  });

  testWidgets('a first page that does not fill the screen asks for the '
      'next one by itself', (tester) async {
    repository.myRequestsPage = (query, cursor) async => Result.success(
      cursor == null
          ? CursorPage(items: rows(0, 1), nextCursor: 'c-2', hasMore: true)
          : CursorPage(items: rows(1, 1)),
    );

    await pumpTab(tester);
    await tester.pump();
    await tester.pump();

    expect(repository.myRequestsCursors, [null, 'c-2']);
  });
}
