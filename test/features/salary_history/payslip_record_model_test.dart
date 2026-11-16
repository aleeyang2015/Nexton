import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/salary_history/data/models/payslip_record_model.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_record.dart';

/// A `GET /payroll/payslips/my` row as `nexton-demo` sends it (the list
/// shape: totals only, no lines). Names are not a real person's.
Map<String, dynamic> listRow() => {
  'id': '2f2e2dfb-2a95-4ee5-ac4e-f97c21201820',
  'payroll_run_id': '60e08b66-2542-42e9-844c-c91626fce33d',
  'employee_id': '729781ee-ab70-40ed-8b6f-eacdfd5dfde6',
  'employee_number': 'EMP-007',
  'employee_name': 'Noy Phommachanh',
  'department_name': 'Sales',
  'position_title': 'Support',
  'base_salary': 10000000,
  'total_earnings': 11800000,
  'total_deductions': 1777492,
  'net_salary': 10022508,
  'employee_ss': 247500,
  'employer_ss': 270000,
  'taxable_income': 11552500,
  'income_tax': 840249,
  'work_days': 21.5,
  'overtime_hours': 2.25,
  'unpaid_leave_days': 0.5,
  'payment_status': 'paid',
  'status': 'paid',
  'created_at': '2026-11-01T09:30:13.194803+07:00',
  'updated_at': '2026-11-05T21:03:56.040049+07:00',
};

/// The same payslip from `GET /payroll/payslips/my/:id`, with everything
/// only the single-payslip call carries.
Map<String, dynamic> detailRow() => {
  ...listRow(),
  'lines': [
    {
      'id': 'line-basic',
      'component_code': 'BASIC',
      'component_name': 'Basic Salary',
      'type': 'earning',
      'category': 'fixed',
      'amount': 10000000,
      'is_taxable': true,
      'sort_order': 0,
      'quantity': 0,
      'quantity_unit': null,
      'rate_per': 0,
      'rate_amount': 0,
    },
    {
      'id': 'line-late',
      'component_code': 'LATE',
      'component_name': 'Late arrival penalty',
      'type': 'deduction',
      'category': 'penalty',
      'amount': 68910,
      'is_taxable': false,
      'sort_order': 960,
      'quantity': 86,
      'quantity_unit': 'minutes',
      'rate_per': 12480,
      'rate_amount': 10000000,
    },
  ],
  'benefits': [
    {'id': 'b1', 'name': 'ປະກັນສຸຂະພາບ', 'amount': 1000000},
    {'id': 'b2', 'name': 'ຄ່າເດີນທາງ', 'amount': 333333.33},
  ],
  'deduction_items': [
    {'id': 'd1', 'deduction_name': 'ພັກວຽກ', 'amount': 100000.5},
  ],
  'overtime_items': [
    {
      'piece_id': 'piece-1',
      'overtime_request_id': 'ot-1',
      'work_date': '2026-10-17',
      'starts_at': '2026-10-17T18:00:00+07:00',
      'ends_at': '2026-10-17T20:15:00+07:00',
      'pay_type': 'percent',
      'pay_value': 150,
      'paid_minutes': 135,
      'base_salary': 10000000,
      'days_per_month': 26,
      'amount': 162259,
    },
  ],
};

void main() {
  group('a list row', () {
    final record = PayslipRecordModel.fromJson(listRow());

    test('reads who and which run', () {
      expect(record.id, '2f2e2dfb-2a95-4ee5-ac4e-f97c21201820');
      expect(record.payrollRunId, '60e08b66-2542-42e9-844c-c91626fce33d');
      expect(record.employeeId, '729781ee-ab70-40ed-8b6f-eacdfd5dfde6');
      expect(record.employeeNumber, 'EMP-007');
      expect(record.employeeName, 'Noy Phommachanh');
      expect(record.departmentName, 'Sales');
      expect(record.positionTitle, 'Support');
    });

    test('money stays whole kip, exactly as sent', () {
      expect(record.baseSalary, 10000000);
      expect(record.totalEarnings, 11800000);
      expect(record.totalDeductions, 1777492);
      expect(record.netSalary, 10022508);
      expect(record.employeeSs, 247500);
      expect(record.employerSs, 270000);
      expect(record.taxableIncome, 11552500);
      expect(record.incomeTax, 840249);
      expect(record.netSalary, isA<int>());
    });

    test('the counts keep their fractions: 0.5 stays 0.5', () {
      expect(record.workDays, 21.5);
      expect(record.overtimeHours, 2.25);
      expect(record.unpaidLeaveDays, 0.5);
    });

    test('both statuses are kept', () {
      expect(record.status, PayslipRunStatus.paid);
      expect(record.paymentStatus, PayslipPaymentStatus.paid);
    });

    test('with no lines sent, every list is empty', () {
      expect(record.lines, isEmpty);
      expect(record.benefits, isEmpty);
      expect(record.deductionItems, isEmpty);
      expect(record.overtimeItems, isEmpty);
    });

    test('created_at and updated_at are read as instants, in local time', () {
      expect(
        record.createdAt,
        DateTime.parse('2026-11-01T09:30:13.194803+07:00').toLocal(),
      );
      expect(record.createdAt!.isUtc, isFalse);
      expect(
        record.updatedAt,
        DateTime.parse('2026-11-05T21:03:56.040049+07:00').toLocal(),
      );
    });

    test('nothing is lost: the server\'s net is not what the phone would '
        'work out, and it is the server\'s that is kept', () {
      // 11,800,000 - 1,777,492 = 10,022,508 here, but the record does not
      // depend on that: change the net alone and it is still what was sent.
      final odd = PayslipRecordModel.fromJson({
        ...listRow(),
        'net_salary': 9999999,
      });

      expect(odd.netSalary, 9999999);
      expect(odd.totalEarnings - odd.totalDeductions, isNot(odd.netSalary));
    });
  });

  group('the pay period', () {
    test('missing: no year, no month, no paid date', () {
      final record = PayslipRecordModel.fromJson(listRow());

      expect(record.periodYear, isNull);
      expect(record.periodMonth, isNull);
      expect(record.paidAt, isNull);
    });

    test('null: the same', () {
      final record = PayslipRecordModel.fromJson({
        ...listRow(),
        'period_year': null,
        'period_month': null,
        'paid_at': null,
      });

      expect(record.periodYear, isNull);
      expect(record.periodMonth, isNull);
      expect(record.paidAt, isNull);
    });

    test('present: read as sent', () {
      final record = PayslipRecordModel.fromJson({
        ...listRow(),
        'period_year': 2026,
        'period_month': 10,
        'paid_at': '2026-11-05T10:00:00+07:00',
      });

      expect(record.periodYear, 2026);
      expect(record.periodMonth, 10);
      expect(
        record.paidAt,
        DateTime.parse('2026-11-05T10:00:00+07:00').toLocal(),
      );
    });

    test('October\'s payslip, made on 1 November, is October: the month is '
        'never taken from created_at', () {
      final record = PayslipRecordModel.fromJson({
        ...listRow(),
        'period_year': 2026,
        'period_month': 10,
      });

      expect(record.createdAt!.month, 11);
      expect(record.periodMonth, 10);
    });

    test('with no period sent, created_at does not stand in for it', () {
      final record = PayslipRecordModel.fromJson(listRow());

      expect(record.createdAt, isNotNull);
      expect(record.periodMonth, isNull);
      expect(record.periodYear, isNull);
    });

    test('December of last year, made in January, keeps its own year', () {
      final record = PayslipRecordModel.fromJson({
        ...listRow(),
        'period_year': 2025,
        'period_month': 12,
        'created_at': '2026-01-02T09:00:00+07:00',
      });

      expect(record.periodYear, 2025);
      expect(record.periodMonth, 12);
    });

    test('a month that is not 1 to 12 is no month', () {
      for (final value in [0, 13, -1, 'october']) {
        final record = PayslipRecordModel.fromJson({
          ...listRow(),
          'period_month': value,
        });

        expect(record.periodMonth, isNull, reason: '$value');
      }
    });

    test('a paid_at that is not a time is no paid date', () {
      final record = PayslipRecordModel.fromJson({
        ...listRow(),
        'paid_at': 'yesterday',
      });

      expect(record.paidAt, isNull);
    });
  });

  group('statuses', () {
    PayslipRecord with_(String key, Object? value) =>
        PayslipRecordModel.fromJson({...listRow(), key: value});

    test('status: approved and paid', () {
      expect(with_('status', 'approved').status, PayslipRunStatus.approved);
      expect(with_('status', 'paid').status, PayslipRunStatus.paid);
    });

    test('a status the App does not know is unknown, not approved', () {
      for (final value in ['calculated', 'draft', '', null, 3]) {
        expect(
          with_('status', value).status,
          PayslipRunStatus.unknown,
          reason: '$value',
        );
      }
    });

    test('payment_status: all four, failed among them', () {
      expect(
        with_('payment_status', 'pending').paymentStatus,
        PayslipPaymentStatus.pending,
      );
      expect(
        with_('payment_status', 'processing').paymentStatus,
        PayslipPaymentStatus.processing,
      );
      expect(
        with_('payment_status', 'paid').paymentStatus,
        PayslipPaymentStatus.paid,
      );
      expect(
        with_('payment_status', 'failed').paymentStatus,
        PayslipPaymentStatus.failed,
      );
    });

    test('a payment_status the App does not know is unknown, not pending',
        () {
      for (final value in ['refunded', '', null]) {
        expect(
          with_('payment_status', value).paymentStatus,
          PayslipPaymentStatus.unknown,
          reason: '$value',
        );
      }
    });
  });

  group('the single payslip', () {
    final record = PayslipRecordModel.fromJson(detailRow());

    test('lines are read in the order sent, with every field', () {
      expect(record.lines, const [
        PayslipRecordLine(
          id: 'line-basic',
          componentCode: 'BASIC',
          componentName: 'Basic Salary',
          type: PayslipLineType.earning,
          category: 'fixed',
          amount: 10000000,
          isTaxable: true,
          sortOrder: 0,
        ),
        PayslipRecordLine(
          id: 'line-late',
          componentCode: 'LATE',
          componentName: 'Late arrival penalty',
          type: PayslipLineType.deduction,
          category: 'penalty',
          amount: 68910,
          sortOrder: 960,
          quantity: 86,
          quantityUnit: 'minutes',
          ratePer: 12480,
          rateAmount: 10000000,
        ),
      ]);
    });

    test('lines sent out of sort_order stay in the order sent', () {
      final lines = (detailRow()['lines'] as List).reversed.toList();
      final reversed = PayslipRecordModel.fromJson({
        ...detailRow(),
        'lines': lines,
      });

      expect(reversed.lines.map((l) => l.componentCode), ['LATE', 'BASIC']);
    });

    test('a line type the App does not know is unknown', () {
      final odd = PayslipRecordModel.fromJson({
        ...listRow(),
        'lines': [
          {'id': 'x', 'type': 'bonus', 'amount': 5},
        ],
      });

      expect(odd.lines.single.type, PayslipLineType.unknown);
      expect(odd.lines.single.amount, 5);
      expect(odd.lines.single.quantityUnit, isNull);
    });

    test('benefits keep their decimals', () {
      expect(record.benefits, const [
        PayslipBenefit(id: 'b1', name: 'ປະກັນສຸຂະພາບ', amount: 1000000),
        PayslipBenefit(id: 'b2', name: 'ຄ່າເດີນທາງ', amount: 333333.33),
      ]);
    });

    test('deduction items read deduction_name and keep their decimals', () {
      expect(record.deductionItems, const [
        PayslipDeductionItem(id: 'd1', name: 'ພັກວຽກ', amount: 100000.5),
      ]);
    });

    test('overtime items are read, every field', () {
      final item = record.overtimeItems.single;

      expect(item.pieceId, 'piece-1');
      expect(item.overtimeRequestId, 'ot-1');
      // A calendar day: the 17th wherever the phone is.
      expect(item.workDate, DateTime(2026, 10, 17));
      expect(
        item.startsAt,
        DateTime.parse('2026-10-17T18:00:00+07:00').toLocal(),
      );
      expect(item.endsAt, DateTime.parse('2026-10-17T20:15:00+07:00').toLocal());
      expect(item.payType, PayslipOvertimePayType.percent);
      expect(item.payValue, 150);
      expect(item.paidMinutes, 135);
      expect(item.baseSalary, 10000000);
      expect(item.daysPerMonth, 26);
      expect(item.amount, 162259);
    });

    test('pay_type: fixed_per_hour, and one the App does not know', () {
      PayslipOvertimePayType payType(Object? value) =>
          PayslipRecordModel.fromJson({
            ...listRow(),
            'overtime_items': [
              {'piece_id': 'p', 'pay_type': value},
            ],
          }).overtimeItems.single.payType;

      expect(payType('fixed_per_hour'), PayslipOvertimePayType.fixedPerHour);
      expect(payType('per_piece'), PayslipOvertimePayType.unknown);
      expect(payType(null), PayslipOvertimePayType.unknown);
    });

    test('the totals are the server\'s, not the lines added up', () {
      // The two lines here come to 10,000,000 earned and 68,910 deducted;
      // the payslip says 11,800,000 and 1,777,492, and that is what is kept.
      expect(record.totalEarnings, 11800000);
      expect(record.totalDeductions, 1777492);
      expect(record.netSalary, 10022508);
    });
  });

  group('what the server leaves out', () {
    test('department and position missing or empty: none', () {
      final json = listRow()
        ..remove('department_name')
        ..['position_title'] = '';
      final record = PayslipRecordModel.fromJson(json);

      expect(record.departmentName, isNull);
      expect(record.positionTitle, isNull);
    });

    test('lists sent as null are empty lists', () {
      final record = PayslipRecordModel.fromJson({
        ...listRow(),
        'lines': null,
        'benefits': null,
        'deduction_items': null,
        'overtime_items': null,
      });

      expect(record.lines, isEmpty);
      expect(record.benefits, isEmpty);
      expect(record.deductionItems, isEmpty);
      expect(record.overtimeItems, isEmpty);
    });

    test('whole numbers sent with a decimal point are the same kip', () {
      final record = PayslipRecordModel.fromJson({
        ...listRow(),
        'net_salary': 10022508.0,
      });

      expect(record.netSalary, 10022508);
    });

    test('a body with no id is not a payslip', () {
      expect(
        () => PayslipRecordModel.fromJson({'net_salary': 5}),
        throwsFormatException,
      );
      expect(
        () => PayslipRecordModel.fromJson({'id': '', 'net_salary': 5}),
        throwsFormatException,
      );
    });

    test('an almost empty body does not throw', () {
      final record = PayslipRecordModel.fromJson({'id': 'p-1'});

      expect(record.id, 'p-1');
      expect(record.netSalary, 0);
      expect(record.status, PayslipRunStatus.unknown);
      expect(record.paymentStatus, PayslipPaymentStatus.unknown);
      expect(record.createdAt, isNull);
    });
  });
}
