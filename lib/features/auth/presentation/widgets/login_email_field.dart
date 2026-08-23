import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Email input with an error border and message
class LoginEmailField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const LoginEmailField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final borderColor =
        errorText != null ? AppColors.error : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        customText(l10n.email),
        heightBx(h: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: l10n.emailHint,
            fillColor: Colors.white,
            filled: true,
            hintStyle: AppTextStyles.hintStyle,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.secondaryVariant),
            ),
          ),
        ),
        if (errorText != null) ...[
          heightBx(h: 6),
          customText(errorText!, color: AppColors.error, fontSize: 14),
        ],
      ],
    );
  }
}
