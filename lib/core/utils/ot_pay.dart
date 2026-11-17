import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import 'ot_pay_type.dart';

export 'ot_pay_type.dart';

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
