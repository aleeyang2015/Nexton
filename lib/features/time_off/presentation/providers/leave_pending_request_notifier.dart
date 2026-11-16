import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/leave_request.dart';
import '../../time_off_providers.dart';

/// The caller's leave request that is waiting for a decision, or null when
/// there is none.
///
/// The server refuses a new request while one waits. The new-request tab
/// reads this to say so before the form is filled in, with a link to the
/// waiting request.
///
/// A failed check reads as "none": no banner is shown and the form stays
/// usable. The server still refuses, with its own message.
class LeavePendingRequestNotifier
    extends AutoDisposeAsyncNotifier<LeaveRequest?> {
  @override
  Future<LeaveRequest?> build() async {
    final result = await ref.read(getPendingLeaveRequestUseCaseProvider)();
    return result.fold((_) => null, (request) => request);
  }
}

final leavePendingRequestNotifierProvider =
    AsyncNotifierProvider.autoDispose<
      LeavePendingRequestNotifier,
      LeaveRequest?
    >(LeavePendingRequestNotifier.new);
