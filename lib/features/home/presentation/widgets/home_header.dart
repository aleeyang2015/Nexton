import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';

/// Avatar, name/role and the notification bell across the top of the home screen
class HomeHeader extends StatelessWidget {
  final String name;
  final String jobTitle;
  final String avatarAsset;

  const HomeHeader({
    super.key,
    required this.name,
    required this.jobTitle,
    required this.avatarAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        widthBx(w: 15),
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: ClipOval(child: assetImg(avatarAsset)),
        ),
        widthBx(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBx(h: 6),
              customText(name, fontWeight: FontWeight.w600, fontSize: 18),
              customText(jobTitle, color: AppColors.subTitle),
            ],
          ),
        ),
        widthBx(),
        Padding(
          padding: const EdgeInsets.only(top: 10, right: 15),
          child: assetImg("assets/icon/bell.png", width: 30, height: 30),
        ),
      ],
    );
  }
}
