import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip.dart';
import 'package:next_on/features/salary_history/presentation/widgets/salary_history_copy.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

/// The payroll API names its `lines[]` in English only and its tenant-entered
/// `benefits` / `deduction_items` in Lao only, so the detail page cannot show
/// either as-is. These cover the code-keyed translation that stands in for the
/// `name`/`name_lo` pair the rest of the API sends.
void main() {
  late AppLocalizations en;
  late AppLocalizations lo;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    lo = await AppLocalizations.delegate.load(const Locale('lo'));
  });

  PayslipLine line(
    String code, {
    String title = 'wire name',
    double quantity = 0,
    String? unit,
  }) => PayslipLine(
    code: code,
    title: title,
    quantity: quantity,
    quantityUnit: unit,
    amount: -1,
  );

  group('lineTitle', () {
    test('translates every system component code', () {
      const codes = [
        'BASIC',
        'EMP-SS',
        'PIT',
        'LATE',
        'ABSENT-LATE',
        'EARLY-OUT',
        'ABSENCE',
      ];

      for (final code in codes) {
        final laoTitle = SalaryHistoryCopy.lineTitle(lo, line(code));
        final enTitle = SalaryHistoryCopy.lineTitle(en, line(code));

        // The English `component_name` never leaks into the Lao UI...
        expect(
          laoTitle,
          isNot('wire name'),
          reason: '$code has no Lao translation',
        );
        // ...and the two languages really are different copy.
        expect(laoTitle, isNot(enTitle), reason: '$code reads the same in both');
      }
    });

    test('the reported case: BASIC reads as Lao under a Lao locale', () {
      final basic = line('BASIC', title: 'Basic Salary');

      expect(SalaryHistoryCopy.lineTitle(lo, basic), 'ເງິນເດືອນພື້ນຖານ');
      expect(SalaryHistoryCopy.lineTitle(en, basic), 'Base Salary');
    });

    test('falls back to the backend wording for an unknown code', () {
      final unknown = line('BONUS-XMAS', title: 'Christmas bonus');

      expect(SalaryHistoryCopy.lineTitle(lo, unknown), 'Christmas bonus');
      expect(SalaryHistoryCopy.lineTitle(en, unknown), 'Christmas bonus');
    });

    test('keeps free-text benefit lines, which carry no code, as sent', () {
      const benefit = PayslipLine(title: 'ປະກັນສຸຂະພາບ', amount: 1000000);

      expect(SalaryHistoryCopy.lineTitle(en, benefit), 'ປະກັນສຸຂະພາບ');
      expect(SalaryHistoryCopy.lineTitle(lo, benefit), 'ປະກັນສຸຂະພາບ');
    });
  });

  group('lineCaption', () {
    test('translates the quantity unit but leaves the code alone', () {
      final late = line('LATE', quantity: 86, unit: 'minutes');

      expect(SalaryHistoryCopy.lineCaption(en, late), 'LATE · 86 minutes');
      expect(SalaryHistoryCopy.lineCaption(lo, late), 'LATE · 86 ນາທີ');
    });

    test('a line with no quantity shows the bare code', () {
      expect(SalaryHistoryCopy.lineCaption(lo, line('EMP-SS')), 'EMP-SS');
    });

    test('a free-text line with neither code nor quantity shows nothing', () {
      const benefit = PayslipLine(title: 'ປະລິນຍາຕີ', amount: 500000);

      expect(SalaryHistoryCopy.lineCaption(lo, benefit), '');
    });

    test('an unrecognised unit is shown rather than dropped', () {
      final odd = line('OT', quantity: 2, unit: 'shifts');

      expect(SalaryHistoryCopy.lineCaption(lo, odd), 'OT · 2 shifts');
    });

    test('drops the decimals on a whole quantity', () {
      final once = line('ABSENT-LATE', quantity: 1, unit: 'times');

      expect(SalaryHistoryCopy.lineCaption(lo, once), 'ABSENT-LATE · 1 ຄັ້ງ');
    });
  });
}
