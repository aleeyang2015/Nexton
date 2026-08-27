import '../../domain/entities/payslip.dart';

abstract class SalaryRemoteDataSource {
  Future<List<Payslip>> history(int year);
}

/// Stand-in for the payroll endpoints, which don't exist yet — returns fixed
/// sample data after a short delay so the UI has something real to render.
/// Swap the body below for a Dio call once the API is available; the
/// repository and everything above it never has to change.
///
/// The per-line breakdowns ([Payslip.earnings] etc.) are illustrative: they
/// mirror the payslip-detail design and do not necessarily foot to the
/// aggregate totals, which stay the source of truth for the summary strip.
class SalaryRemoteDataSourceImpl implements SalaryRemoteDataSource {
  static const _employeeName = 'Sandy Vang';
  static const _employeeCode = 'EMP-002';
  static const _position = 'IT Developer';
  static const _department = 'IT Development';
  static const _baseSalary = 12000000.0;
  static const _allowance = 800000.0;
  static const _socialSecurityRate = 0.045;

  /// The four detail-page sections for a month, synthesised from its
  /// aggregate figures. Callers pass [allowanceLines] etc. to override a
  /// section with hand-authored lines.
  static Payslip _sample({
    required String id,
    required int year,
    required int month,
    DateTime? paidDate,
    required PayslipStatus status,
    required double incomeTax,
    required double otherDeductions,
    required int workingDays,
    double overtimeHours = 0,
    int paidLeaveDays = 0,
    double socialSecurity = 247500,
    List<PayslipLine>? allowanceLines,
    List<PayslipLine>? attendanceDeductionLines,
    List<PayslipLine>? statutoryDeductionLines,
    double? socialSecurityBase,
  }) {
    return Payslip(
      id: id,
      year: year,
      month: month,
      paidDate: paidDate,
      status: status,
      employeeName: _employeeName,
      employeeCode: _employeeCode,
      position: _position,
      department: _department,
      baseSalary: _baseSalary,
      allowance: _allowance,
      socialSecurity: socialSecurity,
      socialSecurityRate: _socialSecurityRate,
      incomeTax: incomeTax,
      otherDeductions: otherDeductions,
      workingDays: workingDays,
      overtimeHours: overtimeHours,
      paidLeaveDays: paidLeaveDays,
      earnings: const [
        PayslipLine(
          title: 'ເງິນເດືອນພື້ນຖານ',
          caption: 'BASIC · ອັດຕາລາຍເດືອນ',
          amount: _baseSalary,
        ),
      ],
      allowances: allowanceLines ??
          const [
            PayslipLine(
              title: 'ເບ້ຍລ້ຽງ / ອື່ນໆ',
              caption: 'ALLOWANCE',
              amount: _allowance,
            ),
          ],
      attendanceDeductions: attendanceDeductionLines ??
          [
            const PayslipLine(
              title: 'ຫักມາຊ້າ',
              caption: 'LATE · 0 ນາທີ',
              amount: 0,
              icon: PayslipLineIcon.lateArrival,
            ),
            const PayslipLine(
              title: 'ຫักຂາດວຽກຊ້າ',
              caption: 'ABSENT-LATE · 0 ຄັ້ງ',
              amount: 0,
              icon: PayslipLineIcon.absentLate,
            ),
            const PayslipLine(
              title: 'ຫักອອກກ່ອນເວລາ',
              caption: 'EARLY-OUT · 0 ນາທີ',
              amount: 0,
              icon: PayslipLineIcon.earlyOut,
            ),
            PayslipLine(
              title: 'ຫักລາບໍ່ຮັບເງິນ',
              caption: 'ABSENCE',
              amount: -otherDeductions,
              icon: PayslipLineIcon.absence,
            ),
          ],
      statutoryDeductions: statutoryDeductionLines ??
          [
            PayslipLine(
              title: 'ປະກັນສັງຄົມ (ພະນັກງານ)',
              caption: 'EMP-SS · 4.5% ຂອງຖານ SS',
              amount: -socialSecurity,
              icon: PayslipLineIcon.socialSecurity,
            ),
            PayslipLine(
              title: 'ອາກອນເງິນເດືອນ',
              caption: 'PIT · ຄິດຈາກ ${_amount(_baseSalary + _allowance - socialSecurity)}',
              amount: -incomeTax,
              icon: PayslipLineIcon.incomeTax,
            ),
          ],
      taxableIncome: _baseSalary + _allowance - socialSecurity,
      socialSecurityBase: socialSecurityBase ?? socialSecurity,
    );
  }

  static String _amount(double v) {
    final s = v.toStringAsFixed(0);
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  static final _payslips = <Payslip>[
    // Not yet processed — demonstrates the "ລໍຖ້າ" (pending) filter.
    _sample(
      id: '2026-09',
      year: 2026,
      month: 9,
      status: PayslipStatus.pending,
      incomeTax: 900000,
      otherDeductions: 4000000,
      workingDays: 18,
    ),
    // Fully itemised — this is the month the payslip-detail design is drawn
    // from.
    _sample(
      id: '2026-08',
      year: 2026,
      month: 8,
      paidDate: DateTime(2026, 8, 20),
      status: PayslipStatus.paid,
      incomeTax: 940249,
      otherDeductions: 4185577,
      workingDays: 22,
      socialSecurityBase: 270000,
      allowanceLines: const [
        PayslipLine(
          title: 'ເບ້ຍຂະຫຍັນ',
          caption: 'ສະໝ່ຳສະເໝີ',
          amount: 50000,
        ),
        PayslipLine(
          title: 'ເບ້ຍລ້ຽງພິເສດ — ໂຄງການ',
          caption: 'ຕາມລະດັບການສະໜັບສະໜູນ',
          amount: 500000,
        ),
        PayslipLine(
          title: 'ເບ້ຍຕຳແໜ່ງ — ວິສະວະກຳ',
          caption: 'ຕາມຕຳແໜ່ງງານ',
          amount: 300000,
        ),
      ],
      attendanceDeductionLines: const [
        PayslipLine(
          title: 'ຫักມາຊ້າ',
          caption: 'LATE · 33 ນາທີ × ₭12,480/ນທ',
          amount: -31731,
          icon: PayslipLineIcon.lateArrival,
        ),
        PayslipLine(
          title: 'ຫักຂາດວຽກຊ້າ',
          caption: 'ABSENT-LATE · 0 ຄັ້ງ',
          amount: 0,
          icon: PayslipLineIcon.absentLate,
        ),
        PayslipLine(
          title: 'ຫักອອກກ່ອນເວລາ',
          caption: 'EARLY-OUT · 0 ນາທີ',
          amount: 0,
          icon: PayslipLineIcon.earlyOut,
        ),
        PayslipLine(
          title: 'ຫักລາຂາດ',
          caption: 'ABSENCE · 9 ວັນ · ອັດຕາ 26%',
          amount: -4153846,
          icon: PayslipLineIcon.absence,
        ),
      ],
      statutoryDeductionLines: const [
        PayslipLine(
          title: 'ປະກັນສັງຄົມ (ພະນັກງານ)',
          caption: 'EMP-SS · 4.5% ຂອງຖານ SS',
          amount: -247500,
          icon: PayslipLineIcon.socialSecurity,
        ),
        PayslipLine(
          title: 'ອາກອນເງິນເດືອນ',
          caption: 'PIT · ຄິດຈາກ 12,552,500',
          amount: -940249,
          icon: PayslipLineIcon.incomeTax,
        ),
        PayslipLine(
          title: 'ປະກັນສັງຄົມ (ບໍ່ບັງຄັບ)',
          caption: 'DED · ລາຍການຫักອື່ນໆ',
          amount: -25000,
          icon: PayslipLineIcon.otherDeduction,
        ),
      ],
    ),
    _sample(
      id: '2026-07',
      year: 2026,
      month: 7,
      paidDate: DateTime(2026, 7, 20),
      status: PayslipStatus.paid,
      incomeTax: 900000,
      otherDeductions: 3901974,
      workingDays: 23,
      paidLeaveDays: 1,
    ),
    _sample(
      id: '2026-06',
      year: 2026,
      month: 6,
      paidDate: DateTime(2026, 6, 19),
      status: PayslipStatus.paid,
      incomeTax: 875000,
      otherDeductions: 3750000,
      workingDays: 21,
      overtimeHours: 2.5,
    ),
    _sample(
      id: '2026-05',
      year: 2026,
      month: 5,
      paidDate: DateTime(2026, 5, 20),
      status: PayslipStatus.paid,
      incomeTax: 860000,
      otherDeductions: 3600000,
      workingDays: 22,
    ),
    _sample(
      id: '2026-04',
      year: 2026,
      month: 4,
      paidDate: DateTime(2026, 4, 20),
      status: PayslipStatus.paid,
      incomeTax: 845000,
      otherDeductions: 3450000,
      workingDays: 22,
    ),
  ];

  @override
  Future<List<Payslip>> history(int year) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final records = _payslips.where((p) => p.year == year).toList()
      ..sort((a, b) => b.month.compareTo(a.month));
    return records;
  }
}
