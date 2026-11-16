import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/payslip.dart';
import '../../salary_history_providers.dart';

/// The full payslip (`GET /payroll/payslips/my/{id}`) behind the detail
/// page, keyed by the payslip id the history list handed over. Same shape as
/// `LeaveBalancesNotifier`: a failure surfaces as [AsyncError] and the page
/// offers a retry.
class PayslipDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<Payslip, String> {
  @override
  Future<Payslip> build(String arg) => _load();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<Payslip> _load() async {
    final result = await ref.read(getPayslipDetailUseCaseProvider)(arg);
    return result.fold((failure) => throw failure, (payslip) => payslip);
  }
}

final payslipDetailNotifierProvider =
    AsyncNotifierProvider.autoDispose
        .family<PayslipDetailNotifier, Payslip, String>(
          PayslipDetailNotifier.new,
        );
