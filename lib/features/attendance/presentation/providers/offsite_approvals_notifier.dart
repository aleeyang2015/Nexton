import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../../attendance_providers.dart';
import '../../domain/entities/offsite_detail.dart';
import '../../domain/entities/time_correction_status.dart';
import 'attendance_approvals_lists.dart';

/// The approvals page's off-site tab (#46): the scans waiting at the
/// approver's step and the ones they decided, from
/// `GET /attendance/offsite-requests/my-approvals`.
class OffsiteApprovalsNotifier
    extends AttendanceApprovalsNotifier<OffsiteRequestDetail> {
  @override
  FutureResult<CursorPage<OffsiteRequestDetail>> fetch(
    TimeCorrectionStatus status,
    String? cursor,
  ) => ref.read(getOffsiteApprovalsUseCaseProvider)((
    status: status,
    cursor: cursor,
  ));
}

final offsiteApprovalsNotifierProvider =
    NotifierProvider.autoDispose<
      OffsiteApprovalsNotifier,
      AttendanceApprovalsState<OffsiteRequestDetail>
    >(OffsiteApprovalsNotifier.new);
