import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../../attendance_providers.dart';
import '../../domain/entities/time_correction_detail.dart';
import '../../domain/entities/time_correction_status.dart';
import 'attendance_approvals_lists.dart';

/// The approvals page's "forgot to scan" tab (#47): the requests waiting at
/// the approver's step and the ones they decided, from
/// `GET /attendance/correction-requests/my-approvals`.
class TimeCorrectionApprovalsNotifier
    extends AttendanceApprovalsNotifier<TimeCorrectionDetail> {
  @override
  FutureResult<CursorPage<TimeCorrectionDetail>> fetch(
    TimeCorrectionStatus status,
    String? cursor,
  ) => ref.read(getTimeCorrectionApprovalsUseCaseProvider)((
    status: status,
    cursor: cursor,
  ));
}

final timeCorrectionApprovalsNotifierProvider =
    NotifierProvider.autoDispose<
      TimeCorrectionApprovalsNotifier,
      AttendanceApprovalsState<TimeCorrectionDetail>
    >(TimeCorrectionApprovalsNotifier.new);
