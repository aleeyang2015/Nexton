import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// The approvals page's search box: matches the employee's name or number.
class TimeCorrectionApprovalSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const TimeCorrectionApprovalSearchField({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.gray200),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.inputStyle,
        decoration: inputDecoration(l10n.timeCorrectionApprovalsSearchHint)
            .copyWith(
              prefixIcon: const Icon(
                Icons.person_search_outlined,
                color: AppColors.textPrimary,
              ),
              enabledBorder: border,
              border: border,
            ),
      ),
    );
  }
}
