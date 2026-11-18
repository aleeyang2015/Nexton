import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';

/// One read-only line of the personal page (#58): its label, and its value
/// or `-` when HR has none.
class PersonalInfoRow extends StatelessWidget {
  final String label;
  final String? value;

  const PersonalInfoRow({super.key, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: customText(
              label,
              fontSize: 13,
              color: AppColors.subTitle,
              maxLine: 2,
            ),
          ),
          widthBx(w: 12),
          Expanded(
            flex: 3,
            child: customText(
              value ?? '-',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              maxLine: 3,
            ),
          ),
        ],
      ),
    );
  }
}
