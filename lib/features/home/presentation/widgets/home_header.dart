import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../profile/presentation/providers/profile_notifier.dart';

/// Avatar, name/role and the notification bell across the top of the home
/// screen. Tapping the avatar opens the profile screen.
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
        widthBx(w: 20),
        GestureDetector(
          onTap: () => context.push(AppRoutes.profile),
          child: _HeaderAvatar(url: data?.avatarUrl),
        ),
        widthBx(w: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              if (!loading && !failed && data?.positionTitle != null)
                _PositionLine(title: data!.positionTitle!),
            ],
          ),
        ),
        widthBx(),
        const _BellButton(),
        widthBx(w: 20),
      ],
    );
  }
}

/// Rounded-square profile picture with the "online" dot on its corner.
class _HeaderAvatar extends StatelessWidget {
  static const double _size = 56;

  final String? url;

  const _HeaderAvatar({required this.url});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: _size,
              height: _size,
              color: AppColors.primaryTint,
              child: (url == null || url!.isEmpty)
                  ? const _AvatarFallback()
                  : Image.network(
                      url!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const _AvatarFallback(),
                    ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.person, size: 30, color: AppColors.primary);
}

/// The role under the name, led by a small brand-colored dot.
class _PositionLine extends StatelessWidget {
  final String title;

  const _PositionLine({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
        ),
        widthBx(w: 6),
        Flexible(
          child: customText(title, color: AppColors.subTitle, fontSize: 14),
        ),
      ],
    );
  }
}

/// The notification bell on a white rounded tile.
class _BellButton extends StatelessWidget {
  const _BellButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: assetImg(
        "assets/icon/bell.png",
        width: 24,
        height: 24,
        color: AppColors.primary,
      ),
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
