import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/utils/ot_pay.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

/// How an OT piece's pay is written: a percent of the hourly pay, or kip per
/// hour.
void main() {
  final en = AppLocalizationsEn();
  final lo = AppLocalizationsLo();

  group('otPayLabel', () {
    test('percent 150 is 150%, in both languages', () {
      expect(otPayLabel(en, OtPayType.percent, 150), '150%');
      expect(otPayLabel(lo, OtPayType.percent, 150), '150%');
    });

    test('fixed per hour 20000 is grouped whole kip per hour', () {
      expect(otPayLabel(lo, OtPayType.fixedPerHour, 20000), '20,000 ກີບ/ຊມ');
      expect(otPayLabel(en, OtPayType.fixedPerHour, 20000), '20,000 kip/h');
    });

    test('a large fixed rate keeps every group', () {
      expect(
        otPayLabel(en, OtPayType.fixedPerHour, 1250000),
        '1,250,000 kip/h',
      );
    });

    test('a type the App does not know is the number, with no unit', () {
      expect(otPayLabel(en, OtPayType.unknown, 150), '150');
      expect(otPayLabel(lo, OtPayType.unknown, 20000), '20,000');
    });

    test('zero is written, not left out', () {
      expect(otPayLabel(en, OtPayType.percent, 0), '0%');
      expect(otPayLabel(en, OtPayType.fixedPerHour, 0), '0 kip/h');
    });
  });

  group('OtPayType.fromWire', () {
    test('reads the server\'s two values, and anything else as unknown', () {
      expect(OtPayType.fromWire('percent'), OtPayType.percent);
      expect(OtPayType.fromWire('fixed_per_hour'), OtPayType.fixedPerHour);
      expect(OtPayType.fromWire('per_piece'), OtPayType.unknown);
      expect(OtPayType.fromWire(null), OtPayType.unknown);
      expect(OtPayType.fromWire(150), OtPayType.unknown);
    });
  });
}
