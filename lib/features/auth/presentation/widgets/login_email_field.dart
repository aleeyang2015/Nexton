import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Email input with a leading icon, an error border and message. Matches the
/// soft look of [AuthPasswordField] so the two fields read as one form.
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
    final radius = BorderRadius.circular(16);
    final borderColor =
        errorText != null ? AppColors.error : AppColors.gray200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        customText(
          l10n.email,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        heightBx(h: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: TextInputType.emailAddress,
            style: AppTextStyles.inputStyle,
            decoration: InputDecoration(
              hintText: l10n.emailHint,
              fillColor: Colors.white,
              filled: true,
              hintStyle: AppTextStyles.hintStyle,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              prefixIcon: const Icon(
                Icons.mail_outline,
                size: 22,
                color: AppColors.gray500,
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 48),
              border: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(color: borderColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(color: AppColors.secondaryVariant),
              ),
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
