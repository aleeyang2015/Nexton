import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/salary_history/presentation/widgets/salary_history_copy.dart';

/// The day and hour counts in a payslip card's stat boxes (#21): at most
/// two decimals, as on the payslip's own page.
void main() {
  test('a long fraction from the server: two decimals, not sixteen', () {
    expect(SalaryHistoryCopy.count(1.6666666666666667), '1.67');
    expect(SalaryHistoryCopy.count(100 / 60), '1.67');
  });

  test('whole numbers and short decimals as they are', () {
    expect(SalaryHistoryCopy.count(22), '22');
    expect(SalaryHistoryCopy.count(2.5), '2.5');
    expect(SalaryHistoryCopy.count(0.82), '0.82');
    expect(SalaryHistoryCopy.count(0), '0');
  });

  test('no zeros left on the end, and no "-0"', () {
    expect(SalaryHistoryCopy.count(1.10), '1.1');
    expect(SalaryHistoryCopy.count(1.999), '2');
    expect(SalaryHistoryCopy.count(-0.001), '0');
  });
}
