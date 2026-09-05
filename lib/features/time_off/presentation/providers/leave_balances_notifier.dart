import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/leave_balance.dart';
import '../../time_off_providers.dart';

/// The per-type quota rollup (`GET /leave/balances/my`) for the current year,
/// shown on the request form's balance card. Invalidated after a submit /
/// edit / cancel so the reserved days stay accurate.
class LeaveBalancesNotifier
    extends AutoDisposeAsyncNotifier<List<LeaveBalance>> {
  @override
  Future<List<LeaveBalance>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<LeaveBalance>> _load() async {
    final result = await ref.read(getLeaveBalancesUseCaseProvider)(
      DateTime.now().year,
    );
    return result.fold((failure) => throw failure, (balances) => balances);
  }
}

final leaveBalancesNotifierProvider =
    AsyncNotifierProvider.autoDispose<
      LeaveBalancesNotifier,
      List<LeaveBalance>
    >(LeaveBalancesNotifier.new);

/// The balance for one leave type, or null while the list is loading / absent.
LeaveBalance? leaveBalanceFor(
  List<LeaveBalance>? balances,
  String? leaveTypeId,
) {
  if (balances == null || leaveTypeId == null) return null;
  for (final balance in balances) {
    if (balance.leaveTypeId == leaveTypeId) return balance;
  }
  return null;
}
