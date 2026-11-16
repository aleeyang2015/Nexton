import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:next_on/app/router/app_router.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/time_off/presentation/pages/leave_request_detail_page.dart';
import 'package:next_on/features/time_off/presentation/pages/leave_request_edit_page.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

import '../support/leave_test_doubles.dart';

/// The leave request page and its edit page are opened by the request's id,
/// so a list row, the "waiting" banner and a push can all reach them.
void main() {
  late FakeLeaveRepository repository;
  late GoRouter router;

  setUp(() {
    repository = FakeLeaveRepository()
      ..requestDetailResult = Result.success(sampleLeaveRequest(id: 'abc-123'));
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
        ...leaveRequestRoutes,
      ],
    );
  });

  Future<void> open(WidgetTester tester, String location, {Object? extra}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [leaveRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    router.push(location, extra: extra);
    await tester.pumpAndSettle();
  }

  test('the locations are built from the id', () {
    expect(AppRoutes.timeOffRequest('abc-123'), '/time-off/request/abc-123');
    expect(
      AppRoutes.timeOffRequestEditOf('abc-123'),
      '/time-off/request/abc-123/edit',
    );
  });

  test('an id with a character a path cannot hold is escaped', () {
    expect(AppRoutes.timeOffRequest('a/b'), '/time-off/request/a%2Fb');
  });

  testWidgets('/time-off/request/:id opens the request page for that id, '
      'with no extra', (tester) async {
    await open(tester, '/time-off/request/abc-123');

    final page = tester.widget<LeaveRequestDetailPage>(
      find.byType(LeaveRequestDetailPage),
    );
    expect(page.requestId, 'abc-123');
    expect(page.initial, isNull);
    // It loaded the request itself.
    expect(repository.requestDetailCalls, ['abc-123']);
    expect(find.byType(LeaveRequestEditPage), findsNothing);
  });

  testWidgets('/time-off/request/:id/edit opens the edit page for that id', (
    tester,
  ) async {
    await open(tester, '/time-off/request/abc-123/edit');

    final page = tester.widget<LeaveRequestEditPage>(
      find.byType(LeaveRequestEditPage),
    );
    expect(page.requestId, 'abc-123');
    expect(find.byType(LeaveRequestDetailPage), findsNothing);
  });

  testWidgets('"edit" is not read as a request id', (tester) async {
    await open(tester, '/time-off/request/abc-123/edit');

    expect(repository.requestDetailCalls, isNot(contains('edit')));
    expect(repository.requestDetailCalls, ['abc-123']);
  });

  testWidgets('the request handed in as extra is used for the first paint', (
    tester,
  ) async {
    final request = sampleLeaveRequest(id: 'abc-123', reason: 'Family trip');

    await open(tester, '/time-off/request/abc-123', extra: request);

    final page = tester.widget<LeaveRequestDetailPage>(
      find.byType(LeaveRequestDetailPage),
    );
    expect(page.initial, request);
  });

  testWidgets('an extra that is another request, or not a request, is '
      'ignored', (tester) async {
    await open(
      tester,
      '/time-off/request/abc-123',
      extra: sampleLeaveRequest(id: 'someone-else'),
    );
    expect(
      tester
          .widget<LeaveRequestDetailPage>(find.byType(LeaveRequestDetailPage))
          .initial,
      isNull,
    );
  });
}
