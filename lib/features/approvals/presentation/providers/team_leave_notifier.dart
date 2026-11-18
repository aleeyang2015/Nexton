import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../time_off/domain/entities/leave_request.dart';
import '../../../time_off/domain/entities/leave_status.dart';
import '../../../time_off/time_off_providers.dart';
import '../../domain/approver_access.dart';
import 'team_list_notifier.dart';

/// "My team" · "ລາພັກ" (#50): `GET /leave/requests/team`, by cursor.
///
/// Never the head's own (the HR branch of the call sends them). A login
/// with HR rights gets the whole company from the server: only the staff
/// of the departments it heads show (decision 29, `headed_department_ids`).
class TeamLeaveNotifier extends TeamListNotifier<LeaveRequest, LeaveStatus> {
  @override
  Future<Result<PagedList<LeaveRequest>>> first(LeaveStatus? status) async =>
      (await ref.read(getTeamLeaveUseCaseProvider)(
        status: status,
      )).mapData(PagedList.first);

  @override
  Future<Result<PagedList<LeaveRequest>>> next(
    PagedList<LeaveRequest> list,
    LeaveStatus? status,
  ) async => (await ref.read(getTeamLeaveUseCaseProvider)(
    status: status,
    cursor: list.nextCursor,
  )).mapData(list.append);

  @override
  bool keeps(LeaveRequest row, User? user) => keepsLeave(row, user);

  /// The rule, on its own for tests.
  static bool keepsLeave(LeaveRequest row, User? user) {
    final me = user?.employeeId;
    if (me != null && row.employeeId == me) return false;
    final access = ApproverAccess.of(user);
    final hr = access.isAdmin || access.canManageLeave;
    if (!hr) return true;
    final department = row.departmentId;
    return department != null &&
        (user?.headedDepartmentIds ?? const []).contains(department);
  }
}

final teamLeaveNotifierProvider =
    NotifierProvider.autoDispose<
      TeamLeaveNotifier,
      TeamListState<LeaveRequest, LeaveStatus>
    >(TeamLeaveNotifier.new);
