import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_record.dart';
import 'package:next_on/features/salary_history/domain/payslip_lines.dart';
import 'package:next_on/features/salary_history/presentation/widgets/payslip_line_copy.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

/// One payslip line as the server sends it. [rate] and [per] are set to
/// figures that would give a different amount if anything multiplied them.
PayslipRecordLine line(
  String code, {
  required PayslipLineType type,
  required String category,
  int amount = 0,
  String? name,
  double quantity = 0,
  String? unit,
  int rate = 0,
  int per = 0,
}) => PayslipRecordLine(
  id: 'line-$code',
  componentCode: code,
  componentName: name ?? 'Server name of $code',
  type: type,
  category: category,
  amount: amount,
  quantity: quantity,
  quantityUnit: unit,
  ratePer: per,
  rateAmount: rate,
);

const earning = PayslipLineType.earning;
const deduction = PayslipLineType.deduction;

PayslipRecord payslip({
  List<PayslipRecordLine> lines = const [],
  List<PayslipBenefit> benefits = const [],
  List<PayslipDeductionItem> deductionItems = const [],
}) => PayslipRecord(
  id: 'p-1',
  // Totals that no sum of the lines below comes to.
  totalEarnings: 99999999,
  totalDeductions: 88888888,
  netSalary: 77777777,
  lines: lines,
  benefits: benefits,
  deductionItems: deductionItems,
);

List<String> codes(List<PayslipRow> rows) => [for (final r in rows) r.code];

void main() {
  final lo = AppLocalizationsLo();
  final en = AppLocalizationsEn();

  group('groupLines: every code the server writes', () {
    // code, type, category, the group it must land in, its Lao title.
    final table = [
      ('BASIC', earning, 'fixed', 'earnings', 'ເງິນເດືອນພື້ນຖານ'),
      ('OT', earning, 'variable', 'earnings', 'ຄ່າລ່ວງເວລາ (ໂອທີ)'),
      ('LOAN', deduction, 'fixed', 'other', 'ຫັກເງິນກູ້'),
      ('LATE', deduction, 'penalty', 'attendance', 'ຫັກມາວຽກຊ້າ'),
      ('EARLY-OUT', deduction, 'penalty', 'attendance', 'ຫັກອອກວຽກກ່ອນເວລາ'),
      (
        'MISSED-PART',
        deduction,
        'penalty',
        'attendance',
        'ຫັກບໍ່ໄດ້ເຂົ້າບາງຊ່ວງຂອງກະ',
      ),
      (
        'ABSENT-LATE',
        deduction,
        'penalty',
        'attendance',
        'ຫັກມື້ມາຊ້າເກີນກຳນົດ',
      ),
      ('ABSENCE', deduction, 'penalty', 'attendance', 'ຫັກຂາດວຽກ'),
      ('UNPAID-LEAVE', deduction, 'penalty', 'attendance', 'ລາພັກບໍ່ໄດ້ຮັບເງິນ'),
      ('EMP-SS', deduction, 'statutory', 'statutory', 'ປະກັນສັງຄົມ'),
      ('PIT', deduction, 'statutory', 'statutory', 'ອາກອນເງິນເດືອນ'),
    ];

    for (final (code, type, category, where, title) in table) {
      test('$code lands in $where, titled $title', () {
        final sections = groupLines(
          payslip(lines: [line(code, type: type, category: category)]),
        );
        final byGroup = {
          'earnings': sections.earnings,
          'attendance': sections.attendance,
          'statutory': sections.statutory,
          'other': sections.otherDeductions,
        };

        for (final entry in byGroup.entries) {
          expect(
            codes(entry.value),
            entry.key == where ? [code] : isEmpty,
            reason: '$code in ${entry.key}',
          );
        }
        expect(sections.unplaced, isEmpty);

        final row = byGroup[where]!.single;
        expect(PayslipLineCopy.title(lo, row), title);
        expect(row.isDeduction, type == deduction);
      });
    }

    test('ATT-SETTLE as an earning lands in earnings, with no caption', () {
      final sections = groupLines(
        payslip(
          lines: [
            line(
              'ATT-SETTLE',
              type: earning,
              category: 'variable',
              amount: 12000,
              quantity: 3,
            ),
          ],
        ),
      );

      final row = sections.earnings.single;
      expect(PayslipLineCopy.title(lo, row), 'ປັບຍອດການເຂົ້າວຽກວັນກ່ອນ');
      expect(row.caption, isNull);
      expect(row.isDeduction, isFalse);
      expect(row.amount, 12000);
      expect(sections.attendance, isEmpty);
    });

    test('ATT-SETTLE as a deduction lands in attendance, with no caption', () {
      final sections = groupLines(
        payslip(
          lines: [
            line(
              'ATT-SETTLE',
              type: deduction,
              category: 'penalty',
              amount: 8000,
            ),
          ],
        ),
      );

      final row = sections.attendance.single;
      expect(row.title, PayslipLineTitle.attendanceSettlement);
      expect(row.caption, isNull);
      expect(row.isDeduction, isTrue);
      expect(sections.earnings, isEmpty);
    });

    test('a company\'s own allowance (unknown code) lands in earnings under '
        'the name the server sent', () {
      final sections = groupLines(
        payslip(
          lines: [
            line(
              'SHIFT-ALW',
              type: earning,
              category: 'variable',
              name: 'Shift allowance',
              amount: 150000,
            ),
          ],
        ),
      );

      final row = sections.earnings.single;
      expect(row.title, isNull);
      expect(PayslipLineCopy.title(lo, row), 'Shift allowance');
      expect(PayslipLineCopy.title(en, row), 'Shift allowance');
      expect(row.amount, 150000);
    });

    test('a company\'s own deduction goes by its category: statutory to '
        'by-law, anything else to other deductions', () {
      final sections = groupLines(
        payslip(
          lines: [
            line('UNION', type: deduction, category: 'fixed'),
            line('PROV-FUND', type: deduction, category: 'statutory'),
            line('UNIFORM', type: deduction, category: 'variable'),
            line('ODD', type: deduction, category: ''),
          ],
        ),
      );

      expect(codes(sections.statutory), ['PROV-FUND']);
      expect(codes(sections.otherDeductions), ['UNION', 'UNIFORM', 'ODD']);
      expect(sections.attendance, isEmpty);
    });

    test('a line is grouped by type and category, never by its name or code: '
        'a "LATE" the server marks as an earning is an earning', () {
      final sections = groupLines(
        payslip(
          lines: [
            line('LATE', type: earning, category: 'variable', amount: 5),
            line(
              'BONUS',
              type: deduction,
              category: 'penalty',
              name: 'Basic Salary',
            ),
          ],
        ),
      );

      expect(codes(sections.earnings), ['LATE']);
      expect(codes(sections.attendance), ['BONUS']);
    });

    test('BASIC sent as a deduction is a deduction: the type decides, and '
        'it is not hoisted into earnings', () {
      final sections = groupLines(
        payslip(lines: [line('BASIC', type: deduction, category: 'fixed')]),
      );

      expect(sections.earnings, isEmpty);
      expect(codes(sections.otherDeductions), ['BASIC']);
      expect(sections.otherDeductions.single.isDeduction, isTrue);
    });

    test('the old guide\'s category names mean nothing here: a deduction '
        'called "tax" is not statutory', () {
      final sections = groupLines(
        payslip(lines: [line('X', type: deduction, category: 'tax')]),
      );

      expect(sections.statutory, isEmpty);
      expect(codes(sections.otherDeductions), ['X']);
    });

    test('a line whose type the App does not know is kept apart, not '
        'dropped and not guessed into a group', () {
      final sections = groupLines(
        payslip(
          lines: [
            line(
              'MYSTERY',
              type: PayslipLineType.unknown,
              category: 'fixed',
              amount: 4200,
            ),
          ],
        ),
      );

      expect(sections.earnings, isEmpty);
      expect(sections.otherDeductions, isEmpty);
      expect(sections.unplaced.single.amount, 4200);
    });
  });

  group('groupLines: order', () {
    test('earnings are BASIC first, then the other earning lines in the '
        'server\'s order, then the benefits', () {
      final sections = groupLines(
        payslip(
          lines: [
            line('OT', type: earning, category: 'variable'),
            line('SHIFT-ALW', type: earning, category: 'variable'),
            line('BASIC', type: earning, category: 'fixed'),
            line('MEAL', type: earning, category: 'fixed'),
          ],
          benefits: const [
            PayslipBenefit(id: 'b1', name: 'ປະກັນສຸຂະພາບ', amount: 1000000),
            PayslipBenefit(id: 'b2', name: 'ຄ່າເດີນທາງ', amount: 300000),
          ],
        ),
      );

      expect(
        [for (final r in sections.earnings) r.code.isEmpty ? r.name : r.code],
        ['BASIC', 'OT', 'SHIFT-ALW', 'MEAL', 'ປະກັນສຸຂະພາບ', 'ຄ່າເດີນທາງ'],
      );
    });

    test('each deduction group keeps the server\'s order', () {
      final sections = groupLines(
        payslip(
          lines: [
            line('UNPAID-LEAVE', type: deduction, category: 'penalty'),
            line('PIT', type: deduction, category: 'statutory'),
            line('LATE', type: deduction, category: 'penalty'),
            line('EMP-SS', type: deduction, category: 'statutory'),
            line('ABSENCE', type: deduction, category: 'penalty'),
          ],
        ),
      );

      expect(codes(sections.attendance), ['UNPAID-LEAVE', 'LATE', 'ABSENCE']);
      expect(codes(sections.statutory), ['PIT', 'EMP-SS']);
    });

    test('other deductions are the lines, then the deduction items', () {
      final sections = groupLines(
        payslip(
          lines: [
            line(
              'LOAN',
              type: deduction,
              category: 'fixed',
              name: 'Loan: motorbike',
            ),
          ],
          deductionItems: const [
            PayslipDeductionItem(id: 'd1', name: 'ພັກວຽກ', amount: 100000),
          ],
        ),
      );

      expect(
        [for (final r in sections.otherDeductions) r.name],
        ['Loan: motorbike', 'ພັກວຽກ'],
      );
      expect(sections.otherDeductions.every((r) => r.isDeduction), isTrue);
    });
  });

  test('the groups are handed out read-only', () {
    final sections = groupLines(
      payslip(lines: [line('BASIC', type: earning, category: 'fixed')]),
    );
    const extra = PayslipRow(
      code: 'X',
      title: null,
      name: 'x',
      caption: null,
      amount: 1,
      isDeduction: false,
    );

    for (final list in [
      sections.earnings,
      sections.attendance,
      sections.statutory,
      sections.otherDeductions,
      sections.unplaced,
    ]) {
      expect(() => list.add(extra), throwsUnsupportedError);
    }
  });

  group('groupLines: what is not there', () {
    test('no lines, no benefits, no items: four empty groups', () {
      final sections = groupLines(payslip());

      expect(sections.earnings, isEmpty);
      expect(sections.attendance, isEmpty);
      expect(sections.statutory, isEmpty);
      expect(sections.otherDeductions, isEmpty);
      expect(sections.unplaced, isEmpty);
    });

    test('EMP-SS and PIT are only sent when above zero: without them the '
        'by-law group is empty, and none is made up', () {
      final sections = groupLines(
        payslip(lines: [line('BASIC', type: earning, category: 'fixed')]),
      );

      expect(sections.statutory, isEmpty);
    });

    test('lines of zero are kept: the six attendance lines arrive every '
        'month', () {
      final sections = groupLines(
        payslip(
          lines: [
            for (final code in const [
              'LATE',
              'ABSENT-LATE',
              'EARLY-OUT',
              'MISSED-PART',
              'ABSENCE',
              'UNPAID-LEAVE',
            ])
              line(code, type: deduction, category: 'penalty'),
          ],
        ),
      );

      expect(sections.attendance, hasLength(6));
      expect(sections.attendance.every((r) => r.amount == 0), isTrue);
    });
  });

  group('amounts', () {
    test('a row\'s amount is the line\'s own, never quantity times a rate: '
        'an attendance line can be cut by the net-pay floor', () {
      final sections = groupLines(
        payslip(
          lines: [
            // 86 minutes at 10,000,000 / 12,480 would be 68,910; the floor
            // cut it to 50,000, and that is what was taken.
            line(
              'LATE',
              type: deduction,
              category: 'penalty',
              amount: 50000,
              quantity: 86,
              unit: 'minutes',
              rate: 10000000,
              per: 12480,
            ),
          ],
        ),
      );

      expect(sections.attendance.single.amount, 50000);
    });

    test('nothing is added up: each row carries one figure the server sent, '
        'and the payslip\'s totals are untouched', () {
      final record = payslip(
        lines: [
          line('BASIC', type: earning, category: 'fixed', amount: 10000000),
          line('OT', type: earning, category: 'variable', amount: 250000),
          line('PIT', type: deduction, category: 'statutory', amount: 840249),
        ],
        benefits: const [PayslipBenefit(id: 'b', name: 'x', amount: 300000)],
      );

      final sections = groupLines(record);
      final amounts = [
        for (final r in [
          ...sections.earnings,
          ...sections.attendance,
          ...sections.statutory,
          ...sections.otherDeductions,
        ])
          r.amount,
      ];

      // The four figures sent, and no fifth (no subtotal row).
      expect(amounts, [10000000, 250000, 300000, 840249]);
      expect(record.totalEarnings, 99999999);
      expect(record.totalDeductions, 88888888);
      expect(record.netSalary, 77777777);
    });

    test('a benefit or deduction item of zero is kept, as zero', () {
      final sections = groupLines(
        payslip(
          benefits: const [PayslipBenefit(id: 'b', name: 'a', amount: 0)],
          deductionItems: const [
            PayslipDeductionItem(id: 'd', name: 'c', amount: 0),
          ],
        ),
      );

      expect(sections.earnings.single.amount, 0);
      expect(sections.otherDeductions.single.amount, 0);
    });

    test('a benefit or deduction item is rounded to whole kip the way the '
        'server rounds it', () {
      final sections = groupLines(
        payslip(
          benefits: const [
            PayslipBenefit(id: 'b1', name: 'a', amount: 25.50),
            PayslipBenefit(id: 'b2', name: 'b', amount: 25.49),
          ],
          deductionItems: const [
            PayslipDeductionItem(id: 'd1', name: 'c', amount: 100000.5),
          ],
        ),
      );

      expect([for (final r in sections.earnings) r.amount], [26, 25]);
      expect(sections.otherDeductions.single.amount, 100001);
    });
  });

  group('roundKip', () {
    const cases = <(num, int)>[
      (25.50, 26),
      (25.49, 25),
      (25.51, 26),
      (0.5, 1),
      (0.49, 0),
      (0, 0),
      (1000000, 1000000),
      (333333.33, 333333),
      (-25.5, -26),
      (-25.49, -25),
      (2.5, 3),
      (3.5, 4),
    ];

    for (final (input, expected) in cases) {
      test('$input → $expected', () => expect(roundKip(input), expected));
    }
  });

  group('lineTitleKey', () {
    const known = {
      'BASIC': PayslipLineTitle.basic,
      'OT': PayslipLineTitle.overtime,
      'LATE': PayslipLineTitle.late,
      'ABSENT-LATE': PayslipLineTitle.absentLate,
      'EARLY-OUT': PayslipLineTitle.earlyOut,
      'MISSED-PART': PayslipLineTitle.missedPart,
      'ABSENCE': PayslipLineTitle.absence,
      'UNPAID-LEAVE': PayslipLineTitle.unpaidLeave,
      'ATT-SETTLE': PayslipLineTitle.attendanceSettlement,
      'LOAN': PayslipLineTitle.loan,
      'EMP-SS': PayslipLineTitle.socialSecurity,
      'PIT': PayslipLineTitle.incomeTax,
    };

    for (final entry in known.entries) {
      test('${entry.key} → ${entry.value.name}', () {
        expect(lineTitleKey(entry.key), entry.value);
      });
    }

    test('every title has a code: none is left without one', () {
      expect(known.values.toSet(), PayslipLineTitle.values.toSet());
    });

    test('a code the App does not know has no title of its own', () {
      for (final code in ['SHIFT-ALW', '', 'late', 'BENEFIT', 'DED', 'OT ']) {
        expect(lineTitleKey(code), isNull, reason: '"$code"');
      }
    });
  });

  group('caption', () {
    // quantity, unit, Lao, English
    const cases = <(double, String?, String?, String?)>[
      (95, 'minutes', '1 ຊມ 35 ນາທີ', '1 h 35 min'),
      (0, 'minutes', '0 ນາທີ', '0 min'),
      (59, 'minutes', '59 ນາທີ', '59 min'),
      (60, 'minutes', '1 ຊມ 0 ນາທີ', '1 h 0 min'),
      (86, 'minutes', '1 ຊມ 26 ນາທີ', '1 h 26 min'),
      (170, 'minutes', '2 ຊມ 50 ນາທີ', '2 h 50 min'),
      (0.5, 'days', '0.5 ວັນ', '0.5 days'),
      (2, 'days', '2 ວັນ', '2 days'),
      (2, 'times', '2 ເທື່ອ', '2 times'),
      (0, 'times', '0 ເທື່ອ', '0 times'),
      (1.25, 'hours', '1.25 ຊົ່ວໂມງ', '1.25 hours'),
      (8, 'hours', '8 ຊົ່ວໂມງ', '8 hours'),
      (1.5, 'hours', '1.5 ຊົ່ວໂມງ', '1.5 hours'),
      (3, null, null, null),
      (3, '', null, null),
      (3, '  ', null, null),
    ];

    for (final (quantity, unit, laoText, enText) in cases) {
      test('$quantity ${unit ?? 'null'} → ${laoText ?? 'no caption'}', () {
        final row = PayslipRow(
          code: 'X',
          title: null,
          name: 'x',
          caption: caption(quantity, unit),
          amount: 0,
          isDeduction: true,
        );

        expect(PayslipLineCopy.caption(lo, row), laoText);
        expect(PayslipLineCopy.caption(en, row), enText);
      });
    }

    test('a whole number has no ".0"; a fraction keeps two places at most',
        () {
      String? number(double q) => caption(q, 'days')?.number;

      expect(number(2), '2');
      expect(number(2.0), '2');
      expect(number(0.5), '0.5');
      expect(number(1.25), '1.25');
      expect(number(0.333333), '0.33');
      expect(number(1.10), '1.1');
    });

    test('near-whole numbers have no ".0" left on them', () {
      String? number(double q) => caption(q, 'days')?.number;

      expect(number(1.999), '2');
      expect(number(7.999), '8');
      expect(number(1.005), isNot(endsWith('.0')));
      expect(number(0.004), '0');
      expect(number(-0.004), '0');
      expect(number(10), '10');
      expect(number(100.5), '100.5');
    });

    test('minutes below zero are shown as sent, never as a positive count',
        () {
      String? text(double q) => PayslipLineCopy.caption(
        en,
        PayslipRow(
          code: 'X',
          title: null,
          name: 'x',
          caption: caption(q, 'minutes'),
          amount: 0,
          isDeduction: true,
        ),
      );

      expect(text(-95), '-95 min');
      expect(text(-1), '-1 min');
    });

    test('a quantity that is not a number has no caption', () {
      expect(caption(double.nan, 'minutes'), isNull);
      expect(caption(double.infinity, 'days'), isNull);
      expect(caption(double.negativeInfinity, 'hours'), isNull);
    });

    test('a caption with nothing in it is no caption', () {
      String? text(PayslipCaption c) => PayslipLineCopy.caption(
        lo,
        PayslipRow(
          code: 'X',
          title: null,
          name: 'x',
          caption: c,
          amount: 0,
          isDeduction: false,
        ),
      );

      expect(text(const PayslipCaption.text('')), isNull);
      expect(text(const PayslipCaption.text('  ')), isNull);
      expect(
        text(
          const PayslipCaption.count(
            unit: PayslipQuantityUnit.other,
            number: '',
          ),
        ),
        isNull,
      );
    });

    test('a unit the App does not know keeps the server\'s word', () {
      final row = PayslipRow(
        code: 'X',
        title: null,
        name: 'x',
        caption: caption(3, 'shifts'),
        amount: 0,
        isDeduction: true,
      );

      expect(row.caption!.unit, PayslipQuantityUnit.other);
      expect(PayslipLineCopy.caption(lo, row), '3 shifts');
    });

    test('the caption never carries the line\'s code', () {
      final sections = groupLines(
        payslip(
          lines: [
            line(
              'LATE',
              type: deduction,
              category: 'penalty',
              quantity: 86,
              unit: 'minutes',
            ),
          ],
        ),
      );

      final text = PayslipLineCopy.caption(lo, sections.attendance.single)!;
      expect(text, '1 ຊມ 26 ນາທີ');
      expect(text.contains('LATE'), isFalse);
    });

    test('a loan\'s caption is its own name; with none sent, no caption', () {
      PayslipRow loan(String name) => groupLines(
        payslip(
          lines: [
            line('LOAN', type: deduction, category: 'fixed', name: name),
          ],
        ),
      ).otherDeductions.single;

      expect(PayslipLineCopy.title(lo, loan('Loan: motorbike')), 'ຫັກເງິນກູ້');
      expect(
        PayslipLineCopy.caption(lo, loan('Loan: motorbike')),
        'Loan: motorbike',
      );
      expect(PayslipLineCopy.caption(lo, loan('  ')), isNull);
    });

    test('a benefit and a deduction item have no caption', () {
      final sections = groupLines(
        payslip(
          benefits: const [PayslipBenefit(id: 'b', name: 'x', amount: 1)],
          deductionItems: const [
            PayslipDeductionItem(id: 'd', name: 'y', amount: 1),
          ],
        ),
      );

      expect(sections.earnings.single.caption, isNull);
      expect(sections.otherDeductions.single.caption, isNull);
    });
  });

  group('the example in the issue', () {
    test('half a day of unpaid leave reads '
        'ລາພັກບໍ່ໄດ້ຮັບເງິນ · 0.5 ວັນ, 96,154, under attendance', () {
      final sections = groupLines(
        payslip(
          lines: [
            line(
              'UNPAID-LEAVE',
              type: deduction,
              category: 'penalty',
              name: 'Unpaid leave',
              quantity: 0.5,
              unit: 'days',
              amount: 96154,
            ),
          ],
        ),
      );

      final row = sections.attendance.single;
      expect(PayslipLineCopy.title(lo, row), 'ລາພັກບໍ່ໄດ້ຮັບເງິນ');
      expect(PayslipLineCopy.caption(lo, row), '0.5 ວັນ');
      expect(row.amount, 96154);
      expect(row.isDeduction, isTrue);
    });
  });

  group('titles and sections in both languages', () {
    test('every known line has an English title that is not its Lao one',
        () {
      for (final title in PayslipLineTitle.values) {
        final row = PayslipRow(
          code: 'X',
          title: title,
          name: 'server name',
          caption: null,
          amount: 0,
          isDeduction: false,
        );
        final laoText = PayslipLineCopy.title(lo, row);
        final enText = PayslipLineCopy.title(en, row);

        expect(laoText, isNot('server name'), reason: title.name);
        expect(enText, isNot('server name'), reason: title.name);
        expect(laoText, isNot(enText), reason: title.name);
        // English text has no Lao letters; Lao text has no Thai ones.
        expect(RegExp(r'[຀-໿]').hasMatch(enText), isFalse);
        expect(RegExp(r'[฀-๿]').hasMatch(laoText), isFalse);
      }
    });

    test('the English titles are the issue\'s', () {
      String title(PayslipLineTitle t) => PayslipLineCopy.title(
        en,
        PayslipRow(
          code: 'X',
          title: t,
          name: 'server name',
          caption: null,
          amount: 0,
          isDeduction: false,
        ),
      );

      expect(title(PayslipLineTitle.overtime), 'Overtime (OT)');
      expect(title(PayslipLineTitle.late), 'Late arrival');
      expect(
        title(PayslipLineTitle.absentLate),
        'Late past the limit (counted as a day)',
      );
      expect(title(PayslipLineTitle.earlyOut), 'Left early');
      expect(title(PayslipLineTitle.missedPart), 'Missed part of a shift');
      expect(title(PayslipLineTitle.absence), 'Absence');
      expect(title(PayslipLineTitle.unpaidLeave), 'Unpaid leave');
      expect(
        title(PayslipLineTitle.attendanceSettlement),
        'Attendance settlement (earlier days)',
      );
      expect(title(PayslipLineTitle.loan), 'Loan repayment');
    });

    test('the four section names', () {
      expect(PayslipLineCopy.earningsSection(lo), 'ລາຍຮັບ');
      expect(PayslipLineCopy.attendanceSection(lo), 'ລາຍການຫັກ — ການເຂົ້າວຽກ');
      expect(PayslipLineCopy.statutorySection(lo), 'ລາຍການຫັກ — ຕາມກົດໝາຍ');
      expect(PayslipLineCopy.otherDeductionsSection(lo), 'ລາຍການຫັກອື່ນໆ');

      expect(PayslipLineCopy.attendanceSection(en), 'Deductions — attendance');
      expect(PayslipLineCopy.statutorySection(en), 'Deductions — by law');
      expect(PayslipLineCopy.otherDeductionsSection(en), 'Other deductions');
    });

    test('the section names are written in Lao letters only', () {
      for (final text in [
        PayslipLineCopy.attendanceSection(lo),
        PayslipLineCopy.statutorySection(lo),
        PayslipLineCopy.otherDeductionsSection(lo),
      ]) {
        expect(RegExp(r'[฀-๿]').hasMatch(text), isFalse);
      }
    });
  });
}
