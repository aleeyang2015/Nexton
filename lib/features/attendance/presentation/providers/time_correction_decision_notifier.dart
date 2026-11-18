import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../attendance_providers.dart';
import '../../data/datasources/approval_decision_code.dart';
import '../../data/datasources/correction_error_code.dart';
import '../../domain/entities/time_correction_detail.dart';
import 'attendance_approvals_lists.dart';
import 'attendance_decision_notifier.dart';
import 'time_correction_approvals_notifier.dart';
import 'time_correction_detail_notifier.dart';

/// Approve or reject one "forgot to scan" request (#47). After a decision
/// its page stays and is read again, so "ຜົນຫຼັງແກ້ໄຂ" (#45) shows.
class TimeCorrectionDecisionNotifier
    extends AttendanceDecisionNotifier<TimeCorrectionDetail> {
  @override
  FutureResult<Unit> approveCall(TimeCorrectionDetail request, String? note) =>
      ref.read(approveTimeCorrectionUseCaseProvider)((
        id: request.id,
        stepId: request.currentStep?.id,
        note: note,
      ));

  @override
  FutureResult<Unit> rejectCall(TimeCorrectionDetail request, String reason) =>
      ref.read(rejectTimeCorrectionUseCaseProvider)((
        id: request.id,
        note: reason,
        stepId: request.currentStep?.id,
      ));

  @override
  AutoDisposeNotifierProvider<
    TimeCorrectionApprovalsNotifier,
    AttendanceApprovalsState<TimeCorrectionDetail>
  >
  get listsProvider => timeCorrectionApprovalsNotifierProvider;

  @override
  Future<void> reloadPage() async {
    final page = timeCorrectionDetailNotifierProvider(arg);
    if (ref.exists(page)) await ref.read(page.notifier).refresh();
  }

  @override
  Set<String> get staleTokens => const {
    ...ApprovalDecisionCode.staleTokens,
    CorrectionErrorCode.tokenRequestGone,
  };

  @override
  bool get staysAfterDecision => true;
}

final timeCorrectionDecisionNotifierProvider = NotifierProvider.autoDispose
    .family<TimeCorrectionDecisionNotifier, AttendanceDecisionState, String>(
      TimeCorrectionDecisionNotifier.new,
    );
