import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/leave_balance.dart';
import '../../time_off_providers.dart';

/// The per-type quota rollup (`GET /leave/balances/my?year=…`) for one year,
/// shown on the request form's balance card.
///
/// The family key is the year. Each leave day is charged to its own year, so
/// a form asking for days next January reads next year's balances, and one
/// asking for days across the new year reads both. Invalidating the provider (after a submit, an
/// edit or a cancel) refreshes every year that is on screen, so the reserved
/// days stay accurate.
class LeaveBalancesNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<LeaveBalance>, int> {
  @override
  Future<List<LeaveBalance>> build(int arg) => _load();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<LeaveBalance>> _load() async {
    final result = await ref.read(getLeaveBalancesUseCaseProvider)(arg);
    return result.fold((failure) => throw failure, (balances) => balances);
  }
}

final leaveBalancesNotifierProvider =
    AsyncNotifierProvider.autoDispose.family<
      LeaveBalancesNotifier,
      List<LeaveBalance>,
      int
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
