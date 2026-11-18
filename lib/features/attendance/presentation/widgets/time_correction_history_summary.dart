import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/time_correction_status.dart';
import 'time_correction_copy.dart';

/// The status filter: a dropdown of "ທັງໝົດ / ລໍຖ້າ / ອະນຸມັດ / ປະຕິເສດ /
/// ຍົກເລີກແລ້ວ", each with its count. A null status is "all".
///
/// [options] defaults to every status; the approvals page passes only the
/// ones an approver acts on.
class TimeCorrectionFilterDropdown extends StatelessWidget {
  final TimeCorrectionStatus? selected;
  /// Each status's count, or null where it is not known (a list the server
  /// pages and filters: "My requests"); a null count shows the plain name.
  final int? Function(TimeCorrectionStatus? status) countOf;
  final ValueChanged<TimeCorrectionStatus?> onSelect;
  final List<TimeCorrectionStatus?> options;

  const TimeCorrectionFilterDropdown({
    super.key,
    required this.selected,
    required this.countOf,
    required this.onSelect,
    this.options = allOptions,
  });

  static const List<TimeCorrectionStatus?> allOptions = [
    null,
    ...TimeCorrectionStatus.values,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryTint, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TimeCorrectionStatus?>(
          value: selected,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.primaryVariant,
          ),
          onChanged: onSelect,
          selectedItemBuilder: (context) => [
            for (final status in options)
              Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    size: 20,
                    color: AppColors.primaryVariant,
                  ),
                  widthBx(w: 10),
                  Expanded(
                    child: customText(
                      TimeCorrectionCopy.filterLabel(
                        l10n,
                        status,
                        countOf(status),
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryVariant,
                    ),
                  ),
                ],
              ),
          ],
          items: [
            for (final status in options)
              DropdownMenuItem(
                value: status,
                child: customText(
                  TimeCorrectionCopy.filterLabel(l10n, status, countOf(status)),
                  fontSize: 15,
                  fontWeight: status == selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: status == selected
                      ? AppColors.primaryVariant
                      : AppColors.textPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
