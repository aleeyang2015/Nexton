import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/global_widgets.dart';

/// Password input with a visibility toggle and an error border.
/// Purely presentational — every value and decision comes from the caller.
///
/// Shared by the login and change-password screens so the two forms cannot
/// drift apart visually.
class AuthPasswordField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final String? errorText;
  final VoidCallback onToggleObscure;
  final ValueChanged<String> onChanged;

  /// Rendered opposite [label] — the login screen puts its "forgot password"
  /// link here.
  final Widget? trailing;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  /// Leading icon inside the field.
  final IconData? prefixIcon;

  /// The softer look — bold label, rounder corners, a hairline border and a
  /// light shadow. Off by default so the login screen stays as it was.
  final bool soft;

  const AuthPasswordField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.onChanged,
    this.errorText,
    this.trailing,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.enabled = true,
    this.prefixIcon,
    this.soft = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(soft ? 16 : 12);
    final idleBorder = soft ? AppColors.gray200 : AppColors.border;
    final borderColor = errorText != null ? AppColors.error : idleBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Both halves shrink rather than overflow: on a narrow phone the
        // label plus a trailing link is wider than the field.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: soft
                  ? customText(
                      label,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )
                  : customText(label),
            ),
            if (trailing != null) ...[
              widthBx(w: 8),
              Flexible(child: trailing!),
            ],
          ],
        ),
        heightBx(h: soft ? 8 : 6),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: soft
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                obscureText: obscure,
                obscuringCharacter: '*',
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textInputAction: textInputAction,
                keyboardType: TextInputType.visiblePassword,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  hintText: hint,
                  hintStyle: AppTextStyles.hintStyle,
                  counterText: '',
                  // Room for the visibility toggle stacked on the right.
                  contentPadding: EdgeInsets.fromLTRB(
                    prefixIcon == null ? 12 : 0,
                    16,
                    48,
                    16,
                  ),
                  prefixIcon: prefixIcon == null
                      ? null
                      : Icon(prefixIcon, size: 22, color: AppColors.gray500),
                  prefixIconConstraints: const BoxConstraints(minWidth: 48),
                  border: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: BorderSide(color: idleBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: BorderSide(color: borderColor, width: 1),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: BorderSide(color: idleBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: const BorderSide(
                      color: AppColors.secondaryVariant,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 20,
                child: GestureDetector(
                  onTap: enabled ? onToggleObscure : null,
                  child: Image.asset(
                    obscure
                        ? "assets/images/view.png"
                        : "assets/images/hide.png",
                    height: 20,
                    width: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null) ...[
          heightBx(h: 6),
          customText(
            errorText!,
            color: AppColors.error,
            fontSize: 14,
            maxLine: 2,
          ),
        ],
      ],
    );
  }
}
