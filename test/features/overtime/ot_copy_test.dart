import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/theme/app_colors.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';
import 'package:next_on/features/overtime/presentation/widgets/ot_copy.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

/// The words and colours of the OT screens.
void main() {
  final lo = AppLocalizationsLo();
  final en = AppLocalizationsEn();

  OtRequest ot({
    String start = '18:00',
    String end = '20:00',
    bool nextDay = false,
    OtStatus status = OtStatus.pending,
  }) => OtRequest(
    id: 'ot-1',
    employeeId: 'e',
    workDate: DateTime(2026, 11, 14),
    startTime: start,
    endTime: end,
    endsNextDay: nextDay,
    status: status,
  );

  group('status', () {
    test('each status has the leave wording and its colour', () {
      expect(OtCopy.statusPill(lo, OtStatus.pending), (
        label: 'ກຳລັງດຳເນີນການ',
        color: AppColors.primary,
      ));
      expect(OtCopy.statusPill(lo, OtStatus.approved), (
        label: 'ອະນຸມັດແລ້ວ',
        color: AppColors.success,
      ));
      expect(OtCopy.statusPill(lo, OtStatus.rejected), (
        label: 'ບໍ່ອະນຸມັດ',
        color: AppColors.danger,
      ));
      expect(OtCopy.statusPill(lo, OtStatus.cancelled), (
        label: 'ຍົກເລີກແລ້ວ',
        color: AppColors.gray500,
      ));
    });

    test('a status the App does not know has no pill, not a guess', () {
      expect(OtCopy.statusPill(lo, OtStatus.unknown), isNull);
    });

    test('in English', () {
      expect(OtCopy.statusPill(en, OtStatus.approved)!.label, en.leaveStatusApproved);
    });
  });

  group('window', () {
    test('the times as sent: 18:00–20:00', () {
      expect(OtCopy.window(lo, ot()), '18:00–20:00');
    });

    test('past midnight: 22:00–02:00 (ມື້ຖັດໄປ) / (next day)', () {
      final late = ot(start: '22:00', end: '02:00', nextDay: true);

      expect(OtCopy.window(lo, late), '22:00–02:00 (ມື້ຖັດໄປ)');
      expect(OtCopy.window(en, late), '22:00–02:00 (next day)');
    });

    test('a missing time leaves no stray dash', () {
      expect(OtCopy.window(lo, ot(end: '')), '18:00');
      expect(OtCopy.window(lo, ot(start: '', end: '')), '');
    });
  });

  group('dates and months', () {
    test('the day as dd/MM/yyyy', () {
      expect(OtCopy.date(DateTime(2026, 1, 5)), '05/01/2026');
    });

    test('the month button: All months, or the month and year', () {
      expect(OtCopy.monthLabel(lo, null), 'ທຸກເດືອນ');
      expect(OtCopy.monthLabel(en, null), 'All months');
      expect(OtCopy.monthLabel(lo, DateTime(2026, 11)), 'ພະຈິກ 2026');
      expect(OtCopy.monthLabel(en, DateTime(2026, 11)), 'November 2026');
    });

    test('short month names for the picker', () {
      expect(OtCopy.shortMonth(lo, 1), 'ມ.ກ.');
      expect(OtCopy.shortMonth(en, 12), 'Dec');
    });
  });
}
