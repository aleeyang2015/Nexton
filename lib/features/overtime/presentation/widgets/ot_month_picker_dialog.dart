import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'ot_copy.dart';

/// What the month picker gave back: a month, or [month] null for "All
/// months". The picker returns null itself when it was closed with Cancel
/// or by tapping outside.
typedef OtMonthChoice = ({DateTime? month});

/// Opens the month picker on [current] (or this month): a year with arrows,
/// the twelve months, "All months" and Cancel.
Future<OtMonthChoice?> showOtMonthPicker(
  BuildContext context, {
  required DateTime? current,
}) => showDialog<OtMonthChoice>(
  context: context,
  builder: (_) => OtMonthPickerDialog(current: current),
);

class OtMonthPickerDialog extends StatefulWidget {
  /// The month chosen now, or null for every month.
  final DateTime? current;

  const OtMonthPickerDialog({super.key, required this.current});

  @override
  State<OtMonthPickerDialog> createState() => _OtMonthPickerDialogState();
}

class _OtMonthPickerDialogState extends State<OtMonthPickerDialog> {
  /// The years the arrows can reach: no month outside them is a real OT
  /// month, and the server would refuse one.
  static const int firstYear = 2000;
  static const int lastYear = 2200;

  late int _year = (widget.current ?? DateTime.now()).year.clamp(
    firstYear,
    lastYear,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = widget.current;

    return AlertDialog(
      title: customText(
        l10n.otPickMonth,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _year <= firstYear
                      ? null
                      : () => setState(() => _year--),
                ),
                customText(
                  '$_year',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _year >= lastYear
                      ? null
                      : () => setState(() => _year++),
                ),
              ],
            ),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              childAspectRatio: 1.6,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var m = 1; m <= 12; m++)
                  _MonthCell(
                    label: OtCopy.shortMonth(l10n, m),
                    selected:
                        current != null &&
                        current.year == _year &&
                        current.month == m,
                    onTap: () => Navigator.of(
                      context,
                    ).pop<OtMonthChoice>((month: DateTime(_year, m))),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop<OtMonthChoice>((month: null)),
          child: customText(l10n.otAllMonths, color: AppColors.primary),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: customText(l10n.cancel, color: AppColors.subTitle),
        ),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MonthCell({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: customText(
            label,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
