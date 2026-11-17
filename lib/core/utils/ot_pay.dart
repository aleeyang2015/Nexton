import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';

/// How an overtime piece is paid (the server's `pay_type`).
///
/// Lives in core, not in a feature, because the payslip's OT pieces and the
/// overtime requests both carry it.
enum OtPayType {
  /// The pay value is a percent of the hourly pay: 150 is 150 %.
  percent,

  /// The pay value is whole kip per hour: 20000 is 20,000 kip an hour.
  fixedPerHour,

  /// A value the App does not know.
  unknown;

  /// Reads the server's `pay_type`; anything but its two values is
  /// [unknown].
  static OtPayType fromWire(Object? value) => switch (value) {
    'percent' => percent,
    'fixed_per_hour' => fixedPerHour,
    _ => unknown,
  };
}

final _grouped = NumberFormat('#,##0', 'en');

/// The pay of an OT piece, as the user reads it: "150%", "20,000 ກີບ/ຊມ" /
/// "20,000 kip/h". A type the App does not know is the number on its own,
/// with no unit guessed at.
String otPayLabel(AppLocalizations l10n, OtPayType payType, int payValue) =>
    switch (payType) {
      OtPayType.percent => '$payValue%',
      OtPayType.fixedPerHour => l10n.payslipOtKipPerHour(
        _grouped.format(payValue),
      ),
      OtPayType.unknown => _grouped.format(payValue),
    };
