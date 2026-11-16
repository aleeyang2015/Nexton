import 'entities/payslip_record.dart';

// Turns a payslip's lines into the rows the payslip page shows: which
// group each belongs to, what it is called, and the small caption under it.
//
// Pure Dart, no Flutter and no words: a title is a [PayslipLineTitle] and a
// caption is numbers and a unit, and the presentation layer puts them into
// the user's language. That keeps every money rule here, where a table test
// can hold it, and out of the widgets.
//
// Two rules above all:
//
// * A row's amount is the line's own `amount`. It is never worked out from
//   `quantity` and a rate: an attendance line can be cut by the net-pay
//   floor, and then `quantity × rate` is not what was taken.
// * Nothing here adds amounts up. The totals are the server's.

/// The payslip lines the App has its own name for, by `component_code`.
/// Any other code (a company's own allowance, say) is shown under the name
/// the server sent.
enum PayslipLineTitle {
  basic,
  overtime,
  late,
  absentLate,
  earlyOut,
  missedPart,
  absence,
  unpaidLeave,
  attendanceSettlement,
  loan,
  socialSecurity,
  incomeTax,
}

/// What a line's quantity counts (`quantity_unit`).
enum PayslipQuantityUnit {
  minutes,
  times,
  days,
  hours,

  /// A unit the App does not know; the caption shows the server's word.
  other,
}

/// The small line under a row's title.
class PayslipCaption {
  /// A count of minutes, as hours and minutes: 95 minutes is 1 and 35.
  /// [hours] is zero for less than an hour.
  const PayslipCaption.minutes({
    required int this.hours,
    required int this.minutes,
  }) : unit = PayslipQuantityUnit.minutes,
       number = null,
       text = null;

  /// A count of [unit]: "0.5", "2", "1.25". [text] is the server's own word
  /// for a unit the App does not know.
  const PayslipCaption.count({
    required PayslipQuantityUnit this.unit,
    required String this.number,
    this.text,
  }) : hours = null,
       minutes = null;

  /// Plain words to show as they are (a loan's own name).
  const PayslipCaption.text(String this.text)
    : unit = null,
      number = null,
      hours = null,
      minutes = null;

  final PayslipQuantityUnit? unit;
  final int? hours;
  final int? minutes;
  final String? number;
  final String? text;

  @override
  bool operator ==(Object other) =>
      other is PayslipCaption &&
      other.unit == unit &&
      other.hours == hours &&
      other.minutes == minutes &&
      other.number == number &&
      other.text == text;

  @override
  int get hashCode => Object.hash(unit, hours, minutes, number, text);

  @override
  String toString() =>
      'PayslipCaption(unit: $unit, hours: $hours, minutes: $minutes, '
      'number: $number, text: $text)';
}

/// One row of the payslip page.
class PayslipRow {
  /// The line's `component_code`; empty for a benefit or a deduction item,
  /// which have none.
  final String code;

  /// The App's own name for the line, or null to show [name].
  final PayslipLineTitle? title;

  /// The name the server sent (`component_name`, a benefit's `name`, a
  /// deduction item's `deduction_name`).
  final String name;
  final PayslipCaption? caption;

  /// Whole kip, as the server sent it (a benefit or deduction item rounded
  /// the way the server rounds it).
  final int amount;

  /// True for a row that takes from the pay.
  final bool isDeduction;

  const PayslipRow({
    required this.code,
    required this.title,
    required this.name,
    required this.caption,
    required this.amount,
    required this.isDeduction,
  });

  @override
  bool operator ==(Object other) =>
      other is PayslipRow &&
      other.code == code &&
      other.title == title &&
      other.name == name &&
      other.caption == caption &&
      other.amount == amount &&
      other.isDeduction == isDeduction;

  @override
  int get hashCode =>
      Object.hash(code, title, name, caption, amount, isDeduction);

  @override
  String toString() =>
      'PayslipRow($code, $title, "$name", $caption, $amount, '
      '${isDeduction ? 'deduction' : 'earning'})';
}

/// A payslip's rows in the four groups the page shows, each in the order
/// the server sent them.
class PayslipSections {
  /// `BASIC` first, then every other earning line, then the benefits.
  final List<PayslipRow> earnings;

  /// Deductions for attendance: late, left early, absent, unpaid leave, and
  /// a settlement that takes money.
  final List<PayslipRow> attendance;

  /// Deductions by law: social security, income tax, and any company
  /// component HR marked as statutory.
  final List<PayslipRow> statutory;

  /// Every other deduction line (a loan, the company's own), then the named
  /// deduction items.
  final List<PayslipRow> otherDeductions;

  /// Lines whose `type` is neither an earning nor a deduction. They belong
  /// to no group; they are kept here, not dropped, so a figure the server
  /// sent is never lost without trace.
  final List<PayslipRow> unplaced;

  const PayslipSections({
    this.earnings = const [],
    this.attendance = const [],
    this.statutory = const [],
    this.otherDeductions = const [],
    this.unplaced = const [],
  });
}

const String _basicCode = 'BASIC';
const String _loanCode = 'LOAN';
const String _settlementCode = 'ATT-SETTLE';
const String _penaltyCategory = 'penalty';
const String _statutoryCategory = 'statutory';

/// Puts [payslip]'s lines, benefits and deduction items into the four
/// groups.
///
/// A line goes by its `type` and `category`, never by its name: `earning`
/// to earnings; a `deduction` with category `penalty` to attendance, with
/// `statutory` to by-law, and any other to other deductions. So a company's
/// own allowance or deduction lands in the right place without the App
/// knowing its code.
///
/// Lines of zero are kept: the six attendance lines arrive every month, and
/// "0 minutes late" is worth seeing.
PayslipSections groupLines(PayslipRecord payslip) {
  final basic = <PayslipRow>[];
  final earnings = <PayslipRow>[];
  final attendance = <PayslipRow>[];
  final statutory = <PayslipRow>[];
  final other = <PayslipRow>[];
  final unplaced = <PayslipRow>[];

  for (final line in payslip.lines) {
    switch (line.type) {
      case PayslipLineType.earning:
        final row = _rowOf(line, isDeduction: false);
        (line.componentCode == _basicCode ? basic : earnings).add(row);

      case PayslipLineType.deduction:
        final row = _rowOf(line, isDeduction: true);
        switch (line.category) {
          case _penaltyCategory:
            attendance.add(row);
          case _statutoryCategory:
            statutory.add(row);
          default:
            other.add(row);
        }

      case PayslipLineType.unknown:
        unplaced.add(_rowOf(line, isDeduction: false));
    }
  }

  return PayslipSections(
    earnings: [
      ...basic,
      ...earnings,
      for (final benefit in payslip.benefits)
        PayslipRow(
          code: '',
          title: null,
          name: benefit.name,
          caption: null,
          amount: roundKip(benefit.amount),
          isDeduction: false,
        ),
    ],
    attendance: attendance,
    statutory: statutory,
    otherDeductions: [
      ...other,
      for (final item in payslip.deductionItems)
        PayslipRow(
          code: '',
          title: null,
          name: item.name,
          caption: null,
          amount: roundKip(item.amount),
          isDeduction: true,
        ),
    ],
    unplaced: unplaced,
  );
}

PayslipRow _rowOf(PayslipRecordLine line, {required bool isDeduction}) {
  final code = line.componentCode;

  return PayslipRow(
    code: code,
    title: lineTitleKey(code),
    name: line.componentName,
    caption: switch (code) {
      // A settlement is a correction for earlier days, not a count.
      _settlementCode => null,
      // A loan's line is named `Loan: <name>`; that name is its caption.
      _loanCode =>
        line.componentName.trim().isEmpty
            ? null
            : PayslipCaption.text(line.componentName.trim()),
      _ => caption(line.quantity, line.quantityUnit),
    },
    // The line's own amount, whatever its quantity and rate would come to.
    amount: line.amount,
    isDeduction: isDeduction,
  );
}

/// The App's own name for a line with this `component_code`, or null for a
/// code it does not know (the page then shows the server's name).
PayslipLineTitle? lineTitleKey(String code) => switch (code) {
  'BASIC' => PayslipLineTitle.basic,
  'OT' => PayslipLineTitle.overtime,
  'LATE' => PayslipLineTitle.late,
  'ABSENT-LATE' => PayslipLineTitle.absentLate,
  'EARLY-OUT' => PayslipLineTitle.earlyOut,
  'MISSED-PART' => PayslipLineTitle.missedPart,
  'ABSENCE' => PayslipLineTitle.absence,
  'UNPAID-LEAVE' => PayslipLineTitle.unpaidLeave,
  'ATT-SETTLE' => PayslipLineTitle.attendanceSettlement,
  'LOAN' => PayslipLineTitle.loan,
  'EMP-SS' => PayslipLineTitle.socialSecurity,
  'PIT' => PayslipLineTitle.incomeTax,
  _ => null,
};

/// The caption for a line's [quantity] in [unit], or null when the line has
/// no unit.
///
/// * `minutes` → hours and minutes (95 is 1 h 35 min; 0 is 0 min).
/// * `times`, `days`, `hours` → the number: `0.5`, `1.25`, and whole
///   numbers without `.0`.
/// * a unit the App does not know → the number, with the server's word.
///
/// A count of zero still has a caption: "0 minutes" is shown, not hidden.
PayslipCaption? caption(double quantity, String? unit) {
  final word = unit?.trim() ?? '';
  if (word.isEmpty) return null;

  switch (word) {
    case 'minutes':
      final total = quantity.round();
      return PayslipCaption.minutes(hours: total ~/ 60, minutes: total % 60);
    case 'times':
      return PayslipCaption.count(
        unit: PayslipQuantityUnit.times,
        number: _number(quantity),
      );
    case 'days':
      return PayslipCaption.count(
        unit: PayslipQuantityUnit.days,
        number: _number(quantity),
      );
    case 'hours':
      return PayslipCaption.count(
        unit: PayslipQuantityUnit.hours,
        number: _number(quantity),
      );
    default:
      return PayslipCaption.count(
        unit: PayslipQuantityUnit.other,
        number: _number(quantity),
        text: word,
      );
  }
}

/// "2", "0.5", "1.25": a count with its decimals only when it has some, two
/// at most.
String _number(double value) {
  if (value == value.roundToDouble()) return value.round().toString();

  final fixed = value.toStringAsFixed(2);
  return fixed.endsWith('0') ? fixed.substring(0, fixed.length - 1) : fixed;
}

/// A benefit's or a deduction item's amount as whole kip. The server holds
/// these with decimals and rounds each one half away from zero (25.50 is
/// 26, 25.49 is 25); this rounds the same way, so the row matches the
/// payslip HR sees.
int roundKip(num amount) => amount.round();
