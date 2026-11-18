import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../attendance_providers.dart';
import '../../data/datasources/offsite_error_code.dart';
import '../../domain/entities/offsite_detail.dart';
import 'attendance_approvals_lists.dart';
import 'attendance_decision_notifier.dart';
import 'offsite_approvals_notifier.dart';
import 'offsite_detail_notifier.dart';

/// Approve or reject one off-site scan (#46). `CHECKIN_NOT_APPROVED` leaves
/// Reject only; after a decision the scan's page goes back to the list.
class OffsiteDecisionNotifier
    extends AttendanceDecisionNotifier<OffsiteRequestDetail> {
  @override
  FutureResult<Unit> approveCall(OffsiteRequestDetail request, String? note) =>
      ref.read(approveOffsiteRequestUseCaseProvider)((
        id: request.id,
        stepId: request.currentStep?.id,
        note: note,
      ));

  @override
  FutureResult<Unit> rejectCall(OffsiteRequestDetail request, String reason) =>
      ref.read(rejectOffsiteRequestUseCaseProvider)((
        id: request.id,
        note: reason,
        stepId: request.currentStep?.id,
      ));

  @override
  AutoDisposeNotifierProvider<
    OffsiteApprovalsNotifier,
    AttendanceApprovalsState<OffsiteRequestDetail>
  >
  get listsProvider => offsiteApprovalsNotifierProvider;

  @override
  Future<void> reloadPage() async {
    final page = offsiteDetailNotifierProvider(arg);
    if (ref.exists(page)) await ref.read(page.notifier).refresh();
  }

  @override
  Set<String> get staleTokens => OffsiteErrorCode.staleTokens;

  @override
  String? get rejectOnlyToken => OffsiteErrorCode.tokenCheckinNotApproved;
}

final offsiteDecisionNotifierProvider = NotifierProvider.autoDispose
    .family<OffsiteDecisionNotifier, AttendanceDecisionState, String>(
      OffsiteDecisionNotifier.new,
    );
