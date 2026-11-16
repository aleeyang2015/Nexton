import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/time_off/domain/entities/leave_approval_step.dart';
import 'package:next_on/features/time_off/domain/entities/leave_status.dart';
import 'package:next_on/features/time_off/presentation/widgets/leave_approval_timeline.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  Future<void> pumpTimeline(
    WidgetTester tester,
    List<LeaveApprovalStep> steps, {
    LeaveStatus? requestStatus,
    String locale = 'en',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: LeaveApprovalTimeline(
              steps: steps,
              requestStatus: requestStatus,
            ),
          ),
        ),
      ),
    );
  }

  /// The node labels, left to right.
  List<String> labels(WidgetTester tester) {
    final found = <(double, String)>[];
    for (final element in find.byType(Text).evaluate()) {
      final text = (element.widget as Text).data;
      if (text == null || int.tryParse(text) != null) continue;
      found.add((tester.getCenter(find.byWidget(element.widget)).dx, text));
    }
    found.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final (_, text) in found) text];
  }

  testWidgets('one node per step after the leading Submitted node', (
    tester,
  ) async {
    await pumpTimeline(tester, const [
      LeaveApprovalStep(
        stepNo: 1,
        role: LeaveStepRole.deptHead,
        status: LeaveStepStatus.pending,
      ),
      LeaveApprovalStep(
        stepNo: 2,
        role: LeaveStepRole.hr,
        status: LeaveStepStatus.waiting,
      ),
    ]);

    expect(labels(tester), [
      en.leaveStepSubmitted,
      en.leaveStepDeptHead,
      en.leaveStepHr,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the nodes are sorted by step_no, whatever order they came in', (
    tester,
  ) async {
    await pumpTimeline(tester, const [
      LeaveApprovalStep(
        stepNo: 2,
        role: LeaveStepRole.hr,
        status: LeaveStepStatus.waiting,
      ),
      LeaveApprovalStep(
        stepNo: 1,
        role: LeaveStepRole.deptHead,
        status: LeaveStepStatus.pending,
      ),
    ]);

    expect(labels(tester), [
      en.leaveStepSubmitted,
      en.leaveStepDeptHead,
      en.leaveStepHr,
    ]);
  });

  testWidgets('an HR-only request shows one step', (tester) async {
    await pumpTimeline(tester, const [
      LeaveApprovalStep(
        stepNo: 1,
        role: LeaveStepRole.hr,
        status: LeaveStepStatus.pending,
      ),
    ]);

    expect(labels(tester), [en.leaveStepSubmitted, en.leaveStepHr]);
  });

  testWidgets('a step shows its role name, with or without an approver', (
    tester,
  ) async {
    await pumpTimeline(tester, const [
      LeaveApprovalStep(
        stepNo: 1,
        role: LeaveStepRole.deptHead,
        approverName: 'Bounmy Sisavath',
        status: LeaveStepStatus.approved,
      ),
      LeaveApprovalStep(
        stepNo: 2,
        role: LeaveStepRole.hr,
        status: LeaveStepStatus.pending,
      ),
    ]);

    expect(find.text(en.leaveStepDeptHead), findsOneWidget);
    expect(find.text(en.leaveStepHr), findsOneWidget);
    // Today the timeline never shows the approver's own name.
    expect(find.text('Bounmy Sisavath'), findsNothing);
  });

  testWidgets('a role the App does not know is labelled as a manager review', (
    tester,
  ) async {
    await pumpTimeline(tester, const [
      LeaveApprovalStep(
        stepNo: 1,
        role: LeaveStepRole.unknown,
        status: LeaveStepStatus.pending,
      ),
    ]);

    expect(labels(tester), [
      en.leaveStepSubmitted,
      en.leaveStepManagerReview,
    ]);
  });

  testWidgets('each status has its own mark: done, in progress, rejected, '
      'and a number for a step still to come', (tester) async {
    await pumpTimeline(tester, const [
      LeaveApprovalStep(
        stepNo: 1,
        role: LeaveStepRole.deptHead,
        status: LeaveStepStatus.approved,
      ),
      LeaveApprovalStep(
        stepNo: 2,
        role: LeaveStepRole.hr,
        status: LeaveStepStatus.rejected,
      ),
      LeaveApprovalStep(
        stepNo: 3,
        role: LeaveStepRole.unknown,
        status: LeaveStepStatus.waiting,
      ),
    ]);

    // Submitted and the approved step.
    expect(find.byIcon(Icons.check), findsNWidgets(2));
    expect(find.byIcon(Icons.close), findsOneWidget);
    // The waiting step is the fourth node.
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('a pending step shows the in-progress mark', (tester) async {
    await pumpTimeline(tester, const [
      LeaveApprovalStep(
        stepNo: 1,
        role: LeaveStepRole.hr,
        status: LeaveStepStatus.pending,
      ),
    ]);

    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('no steps at all still shows the Submitted node', (tester) async {
    await pumpTimeline(tester, const []);

    expect(labels(tester), [en.leaveStepSubmitted]);
    expect(tester.takeException(), isNull);
  });

  group('a cancelled request', () {
    const waitingChain = [
      LeaveApprovalStep(
        stepNo: 1,
        role: LeaveStepRole.deptHead,
        // Cancelling changes only the request: the step still says pending.
        status: LeaveStepStatus.pending,
      ),
      LeaveApprovalStep(
        stepNo: 2,
        role: LeaveStepRole.hr,
        status: LeaveStepStatus.waiting,
      ),
    ];

    testWidgets('ends in a Cancelled node', (tester) async {
      await pumpTimeline(
        tester,
        waitingChain,
        requestStatus: LeaveStatus.cancelled,
      );

      expect(find.text(en.leaveStatusCancelled), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('no step is lit as waiting for a decision', (tester) async {
      await pumpTimeline(
        tester,
        waitingChain,
        requestStatus: LeaveStatus.cancelled,
      );

      // The "being decided now" mark is gone; both steps show their number,
      // as steps not reached do.
      expect(find.byIcon(Icons.more_horiz), findsNothing);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('a step approved before the cancel keeps its tick', (
      tester,
    ) async {
      await pumpTimeline(tester, const [
        LeaveApprovalStep(
          stepNo: 1,
          role: LeaveStepRole.deptHead,
          status: LeaveStepStatus.approved,
        ),
        LeaveApprovalStep(
          stepNo: 2,
          role: LeaveStepRole.hr,
          status: LeaveStepStatus.pending,
        ),
      ], requestStatus: LeaveStatus.cancelled);

      // Submitted and the department head.
      expect(find.byIcon(Icons.check), findsNWidgets(2));
      expect(find.byIcon(Icons.more_horiz), findsNothing);
    });

    testWidgets('a request that is not cancelled has no Cancelled node, and '
        'its pending step is lit', (tester) async {
      await pumpTimeline(
        tester,
        waitingChain,
        requestStatus: LeaveStatus.pending,
      );

      expect(find.text(en.leaveStatusCancelled), findsNothing);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });
  });

  group('when a step was decided', () {
    final at = DateTime(2026, 11, 12, 14, 5);

    testWidgets('an approved and a rejected step show their date and time', (
      tester,
    ) async {
      await pumpTimeline(tester, [
        LeaveApprovalStep(
          stepNo: 1,
          role: LeaveStepRole.deptHead,
          status: LeaveStepStatus.approved,
          decidedAt: at,
        ),
        LeaveApprovalStep(
          stepNo: 2,
          role: LeaveStepRole.hr,
          status: LeaveStepStatus.rejected,
          decidedAt: DateTime(2026, 11, 13, 9, 30),
        ),
      ]);

      expect(find.text('12 Nov 14:05'), findsOneWidget);
      expect(find.text('13 Nov 09:30'), findsOneWidget);
    });

    testWidgets('in Lao the month is Lao and the digits are Latin', (
      tester,
    ) async {
      await pumpTimeline(tester, [
        LeaveApprovalStep(
          stepNo: 1,
          role: LeaveStepRole.deptHead,
          status: LeaveStepStatus.approved,
          decidedAt: at,
        ),
      ], locale: 'lo');

      expect(find.text('12 ພ.ຈ. 14:05'), findsOneWidget);
    });

    testWidgets('a step not decided shows no time', (tester) async {
      await pumpTimeline(tester, const [
        LeaveApprovalStep(
          stepNo: 1,
          role: LeaveStepRole.deptHead,
          status: LeaveStepStatus.pending,
        ),
      ]);

      expect(find.textContaining(':'), findsNothing);
    });

    testWidgets('a decided step with no approver still shows its role', (
      tester,
    ) async {
      await pumpTimeline(tester, [
        LeaveApprovalStep(
          stepNo: 1,
          role: LeaveStepRole.hr,
          status: LeaveStepStatus.approved,
          decidedAt: at,
        ),
      ]);

      expect(find.text(en.leaveStepHr), findsOneWidget);
    });
  });
}
