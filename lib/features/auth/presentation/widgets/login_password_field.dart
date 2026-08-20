import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/global_widgets.dart';

/// Password input with a visibility toggle and an error border.
/// Purely presentational — state comes from the caller.
class LoginPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final String? errorText;
  final VoidCallback onToggleObscure;
  final ValueChanged<String> onChanged;

  const LoginPasswordField({
    super.key,
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        errorText != null ? AppColors.error : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            customText("ລະຫັດຜ່ານ"),
            customText(
              "ລືມລະຫັດຜ່ານ ?",
              color: Colors.blueAccent,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
        heightBx(h: 6),
        Stack(
          children: [
            TextField(
              controller: controller,
              obscureText: obscure,
              obscuringCharacter: '*',
              onChanged: onChanged,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                hintText: 'ປ້ອນລະຫັດຜ່ານ',
                hintStyle: AppTextStyles.hintStyle,
                counterText: '',
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
            Positioned(
              top: 16,
              right: 20,
              child: GestureDetector(
                onTap: onToggleObscure,
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
        if (errorText != null) ...[
          heightBx(h: 6),
          customText(errorText!, color: AppColors.error, fontSize: 14),
        ],
      ],
    );
  }
}
