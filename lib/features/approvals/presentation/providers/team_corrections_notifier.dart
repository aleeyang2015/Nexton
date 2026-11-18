import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paged_list.dart';
import '../../../../core/utils/result.dart';
import '../../../attendance/attendance_providers.dart';
import '../../../attendance/domain/entities/time_correction_detail.dart';
import '../../../attendance/domain/entities/time_correction_status.dart';
import '../../../auth/domain/entities/user.dart';
import 'team_list_notifier.dart';

/// "My team" · "ລືມລົງເວລາ" (#50): `GET /correction-requests/team`, by page
/// number. The server already keeps it to the departments the caller heads
/// (HR rights add nothing); the head's own are left out (they are in "My
/// requests").
class TeamCorrectionsNotifier
    extends TeamListNotifier<TimeCorrectionDetail, TimeCorrectionStatus> {
  @override
  Future<Result<PagedList<TimeCorrectionDetail>>> first(
    TimeCorrectionStatus? status,
  ) async => (await ref.read(getTeamCorrectionsUseCaseProvider)(status: status))
      .mapData(
        (page) => PagedList.firstNumbered(
          items: page.items,
          page: page.page,
          totalPages: page.totalPages,
          keyOf: _id,
        ),
      );

  @override
  Future<Result<PagedList<TimeCorrectionDetail>>> next(
    PagedList<TimeCorrectionDetail> list,
    TimeCorrectionStatus? status,
  ) async =>
      (await ref.read(getTeamCorrectionsUseCaseProvider)(
        status: status,
        page: list.nextPage ?? 1,
      )).mapData(
        (page) => list.appendNumbered(
          items: page.items,
          page: page.page,
          totalPages: page.totalPages,
          keyOf: _id,
        ),
      );

  @override
  bool keeps(TimeCorrectionDetail row, User? user) {
    final me = user?.employeeId;
    return me == null || row.employee.id != me;
  }

  static Object _id(TimeCorrectionDetail row) => row.id;
}

final teamCorrectionsNotifierProvider =
    NotifierProvider.autoDispose<
      TeamCorrectionsNotifier,
      TeamListState<TimeCorrectionDetail, TimeCorrectionStatus>
    >(TeamCorrectionsNotifier.new);
