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
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = errorText != null ? AppColors.error : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Both halves shrink rather than overflow: on a narrow phone the
        // label plus a trailing link is wider than the field.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: customText(label)),
            if (trailing != null) ...[
              widthBx(w: 8),
              Flexible(child: trailing!),
            ],
          ],
        ),
        heightBx(h: 6),
        Stack(
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                hintText: hint,
                hintStyle: AppTextStyles.hintStyle,
                counterText: '',
                // Room for the visibility toggle stacked on the right.
                contentPadding: const EdgeInsets.fromLTRB(12, 16, 48, 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor, width: 1),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  obscure ? "assets/images/view.png" : "assets/images/hide.png",
                  height: 20,
                  width: 20,
                ),
              ),
            ),
          ],
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
