import '../../../../core/utils/result.dart';
import '../entities/payslip.dart';

/// Contract the presentation layer depends on. The implementation lives in
/// data/repositories.
abstract class SalaryRepository {
  /// Every payslip for [year], newest month first.
  FutureResult<List<Payslip>> history(int year);
}
