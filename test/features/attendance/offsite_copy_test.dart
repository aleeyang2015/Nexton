import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_outcome.dart';
import 'package:next_on/features/attendance/domain/entities/punch_outcome.dart';
import 'package:next_on/features/attendance/presentation/widgets/offsite_copy.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

/// What the off-site form says about a refused scan.
void main() {
  final en = AppLocalizationsEn();
  final lo = AppLocalizationsLo();

  group('OffsiteCopy.blocked', () {
    // #115: the server's answer word for word, in English only.
    const serverNoShift =
        'Cannot clock in — no work shift is assigned to this employee. '
        'Ask HR to assign a shift first.';

    test('no shift today (#115): the App\'s own text in each language, '
        'never the server\'s English, as on the phone clock-in', () {
      const blocked = OffsiteBlocked(
        rule: AttendanceRule.noShiftAssigned,
        message: serverNoShift,
      );

      expect(OffsiteCopy.blocked(en, blocked), en.ruleNoShiftAssigned);
      expect(OffsiteCopy.blocked(lo, blocked), lo.ruleNoShiftAssigned);
    });

    test('every other refusal still puts the server\'s words first', () {
      const blocked = OffsiteBlocked(
        rule: AttendanceRule.tooEarlyCheckin,
        message: 'Clocking in opens at 07:45.',
      );

      expect(OffsiteCopy.blocked(lo, blocked), 'Clocking in opens at 07:45.');
    });
  });
}
