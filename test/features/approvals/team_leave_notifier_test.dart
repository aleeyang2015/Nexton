import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/network/paged_list.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/approvals/presentation/providers/team_leave_notifier.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';
import 'package:next_on/features/time_off/domain/entities/leave_request.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';

import '../../support/approver_access_test_doubles.dart';
import '../../support/leave_test_doubles.dart';

/// "My team" · leave (#50).
void main() {
  late FakeLeaveRepository repository;
  late ProviderContainer container;

  const me = 'e-head';
  final head = approverTestUser(employeeId: me);

  /// A head with HR leave rights, heading Sales only.
  final hrHead = User(
    id: 'u-hr',
    tenantId: 't',
    email: 'hr@x.la',
    firstName: 'H',
    lastName: 'R',
    permissions: const ['corehr:leaveRequest:manage'],
    employeeId: me,
    isDepartmentHead: true,
    headedDepartmentIds: const ['d-sales'],
  );

  LeaveRequest leave(String id, {String employeeId = 'e-noy', String? dept}) =>
      sampleLeaveRequest(id: id, employeeId: employeeId, departmentId: dept);

  setUp(() => repository = FakeLeaveRepository());

  Future<void> start(User user) async {
    container = ProviderContainer(
      overrides: [
        leaveRepositoryProvider.overrideWithValue(repository),
        signedInAs(user),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authSessionProvider.future);
    final sub = container.listen(teamLeaveNotifierProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
  }

  List<String> visible() => container
      .read(teamLeaveNotifierProvider)
      .visible
      .map((r) => r.id)
      .toList();

  test('nothing is asked for until the list is first shown', () {
    final container = ProviderContainer(
      overrides: [
        leaveRepositoryProvider.overrideWithValue(repository),
        signedInAs(head),
      ],
    );
    addTearDown(container.dispose);
    expect(repository.teamCalls, isEmpty);
  });

  test('the head\'s own requests are left out', () async {
    repository.teamPage = (status, cursor) async => Result.success(
      CursorPage.single([leave('mine', employeeId: me), leave('noy')]),
    );
    await start(head);

    expect(visible(), ['noy']);
  });

  test(
    'a plain head: every row of the team, whatever its department',
    () async {
      repository.teamPage = (status, cursor) async => Result.success(
        CursorPage.single([
          leave('a', dept: 'd-sales'),
          leave('b', dept: 'd-x'),
        ]),
      );
      await start(head);

      expect(visible(), ['a', 'b']);
    },
  );

  test('a head with HR rights (the whole company): only the departments it '
      'heads, never its own, never a row with no department', () async {
    repository.teamPage = (status, cursor) async => Result.success(
      CursorPage.single([
        leave('sales', dept: 'd-sales'),
        leave('kitchen', dept: 'd-kitchen'),
        leave('none'),
        leave('mine', employeeId: me, dept: 'd-sales'),
      ]),
    );
    await start(hrHead);

    expect(visible(), ['sales']);
  });

  test('a chip asks the server for that status, from the first page', () async {
    await start(head);
    container
        .read(teamLeaveNotifierProvider.notifier)
        .select(LeaveStatus.pending);
    await pumpEventQueue();

    expect(repository.teamCalls.last, (
      status: LeaveStatus.pending,
      cursor: null,
    ));
  });

  test('a page filtered down to 0 rows, with more to come, asks for the next '
      'by itself; "none" only once the list has ended', () async {
    repository.teamPage = (status, cursor) async => Result.success(
      cursor == null
          ? CursorPage(
              items: [
                for (var i = 0; i < 20; i++) leave('x$i', dept: 'd-kitchen'),
              ],
              nextCursor: 'c1',
              hasMore: true,
            )
          : CursorPage.single([leave('found', dept: 'd-sales')]),
    );
    await start(hrHead);

    expect(repository.teamCalls.map((c) => c.cursor), [null, 'c1']);
    expect(visible(), ['found']);
    expect(
      container.read(teamLeaveNotifierProvider).rows.value!.hasMore,
      false,
    );
  });
}
