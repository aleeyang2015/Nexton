import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../profile/presentation/providers/profile_notifier.dart';

/// Avatar, name/role and the notification bell across the top of the home
/// screen.
///
/// Everything it shows comes from [profileNotifierProvider]; the widget
/// fetches nothing itself and holds no profile logic.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(profileNotifierProvider);
    final loading = profile.isLoading && !profile.hasValue;
    final failed = profile.hasError;
    final data = profile.valueOrNull;

    return Row(
      children: [
        widthBx(w: 15),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: appAvatar(url: data?.avatarUrl, size: 60),
        ),
        widthBx(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBx(h: 6),
              if (loading)
                const _HeaderLoading()
              else if (failed)
                InkWell(
                  onTap: () =>
                      ref.read(profileNotifierProvider.notifier).refresh(),
                  child: customText(
                    l10n.retry,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                customText(
                  data?.fullName ?? '',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              if (!loading && !failed && data?.positionTitle != null)
                customText(data!.positionTitle!, color: AppColors.subTitle),
            ],
          ),
        ),
        widthBx(),
        Padding(
          padding: const EdgeInsets.only(top: 10, right: 15),
          child: assetImg(
            "assets/icon/bell.png",
            width: 30,
            height: 30,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

/// Sweeping placeholder for the name/role lines while the profile loads —
/// same silhouette as [HomeShimmer]'s header so the cold-start handoff to
/// this widget doesn't jump.
class _HeaderLoading extends StatelessWidget {
  const _HeaderLoading();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 120, height: 16),
          heightBx(h: 8),
          const ShimmerBox(width: 90, height: 14),
        ],
      ),
    );
  }
}
