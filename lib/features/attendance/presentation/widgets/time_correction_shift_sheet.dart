import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../profile/domain/entities/shift_detail.dart';
import 'attendance_copy.dart';

/// Opens the segment chooser behind the shift card's swap button and returns
/// the pick, or null when the sheet is dismissed.
Future<ShiftDetail?> showTimeCorrectionShiftSheet(
  BuildContext context, {
  required List<ShiftDetail> details,
  required ShiftDetail? selected,
}) {
  return showModalBottomSheet<ShiftDetail>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ShiftSheet(details: details, selected: selected),
  );
}

class _ShiftSheet extends StatelessWidget {
  final List<ShiftDetail> details;
  final ShiftDetail? selected;

  const _ShiftSheet({required this.details, required this.selected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            customText(
              l10n.timeCorrectionPickSegment,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            heightBx(h: 8),
            for (final detail in details)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.schedule,
                  color: AppColors.primaryVariant,
                ),
                title: customText(
                  AttendanceCopy.shiftDetailLine(locale, detail),
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                trailing: detail == selected
                    ? const Icon(Icons.check, color: AppColors.primaryVariant)
                    : null,
                onTap: () => Navigator.of(context).pop(detail),
              ),
          ],
        ),
      ),
    );
  }
}
