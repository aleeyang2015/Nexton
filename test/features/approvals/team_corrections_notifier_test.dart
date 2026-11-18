import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/network/paged_list.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/approvals/presentation/providers/team_corrections_notifier.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';

import '../../support/approver_access_test_doubles.dart';
import '../../support/attendance_test_doubles.dart';
import '../../support/correction_approval_test_doubles.dart';

/// "My team" · "forgot to scan" (#50).
void main() {
  late FakeAttendanceRepository repository;
  late ProviderContainer container;
  const me = 'e-head';

  setUp(() => repository = FakeAttendanceRepository());

  Future<void> start() async {
    container = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(repository),
        signedInAs(approverTestUser(employeeId: me)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authSessionProvider.future);
    final sub = container.listen(teamCorrectionsNotifierProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
  }

  test('the head\'s own are left out (they are in "My requests")', () async {
    repository.teamCorrectionsAnswer = (status, page) => Result.success(
      NumberedPage(
        items: [
          correctionForApproval(id: 'mine', employeeId: me),
          correctionForApproval(id: 'noy'),
        ],
        page: 1,
        totalPages: 1,
      ),
    );
    await start();

    expect(
      container.read(teamCorrectionsNotifierProvider).visible.map((r) => r.id),
      ['noy'],
    );
  });

  test('25 requests: page 1, then page 2 once on load more', () async {
    repository.teamCorrectionsAnswer = (status, page) => Result.success(
      NumberedPage(
        items: [
          for (var i = 0; i < (page == 1 ? 20 : 5); i++)
            correctionForApproval(id: 'p$page-$i'),
        ],
        page: page,
        totalPages: 2,
      ),
    );
    await start();
    final notifier = container.read(teamCorrectionsNotifierProvider.notifier);

    await Future.wait([notifier.loadMore(), notifier.loadMore()]);
    await notifier.loadMore();

    expect(repository.teamCorrectionCalls.map((c) => c.page), [1, 2]);
    expect(
      container.read(teamCorrectionsNotifierProvider).visible,
      hasLength(25),
    );
  });

  test(
    'a first page of the head\'s own only asks for the next by itself',
    () async {
      repository.teamCorrectionsAnswer = (status, page) => Result.success(
        NumberedPage(
          items: page == 1
              ? [
                  for (var i = 0; i < 20; i++)
                    correctionForApproval(id: 'm$i', employeeId: me),
                ]
              : [correctionForApproval(id: 'noy')],
          page: page,
          totalPages: 2,
        ),
      );
      await start();

      expect(repository.teamCorrectionCalls.map((c) => c.page), [1, 2]);
      expect(
        container
            .read(teamCorrectionsNotifierProvider)
            .visible
            .map((r) => r.id),
        ['noy'],
      );
    },
  );
}
