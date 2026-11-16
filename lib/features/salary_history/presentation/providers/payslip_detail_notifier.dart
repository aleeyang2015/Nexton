import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/payslip_record.dart';
import '../../salary_history_providers.dart';

/// One payslip in full (`GET /payroll/payslips/my/:id`), as the server sends
/// it, keyed by its id. The payslip page reads it from here, so the page can
/// be opened from the list, a link or a push that carries only the id.
///
/// A failure is kept as the state's error, for the page to say what it is:
/// not available (404), payroll not turned on, or could not load.
class PayslipDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<PayslipRecord, String> {
  @override
  Future<PayslipRecord> build(String arg) => _load();

  /// Loads the payslip again after a failed load.
  ///
  /// The state stays what it was (the failure) with `isLoading` set while
  /// the new answer is on its way, so the page can show that it is trying
  /// without flashing its first-load placeholder.
  Future<void> retry() async {
    state = const AsyncLoading<PayslipRecord>().copyWithPrevious(state);
    state = await AsyncValue.guard(_load);
  }

  Future<PayslipRecord> _load() async {
    final result = await ref.read(getMyPayslipUseCaseProvider)(arg);
    return result.fold((failure) => throw failure, (payslip) => payslip);
  }
}

final payslipDetailNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<PayslipDetailNotifier, PayslipRecord, String>(
      PayslipDetailNotifier.new,
    );
