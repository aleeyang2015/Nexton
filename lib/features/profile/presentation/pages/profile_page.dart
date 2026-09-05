import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/coming_soon_page.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../features/auth/presentation/providers/auth_session_notifier.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/profile_notifier.dart';

/// "ໂປຣຟາຍ" tab. Profile summary + a settings-style menu.
///
/// Identity and photo come from [profileNotifierProvider]. The stats row is
/// still placeholder — no endpoint reports it yet.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(profileNotifierProvider);
    final loading = profile.isLoading && !profile.hasValue;
    final data = profile.valueOrNull;

    return Container(
      color: AppColors.homeBackground,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              customText(
                l10n.profile,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                alight: TextAlign.center,
              ),
              heightBx(h: 24),
              Center(child: _Avatar(avatarUrl: data?.avatarUrl)),
              heightBx(h: 16),
              if (loading)
                const Center(child: ShimmerBox(width: 140, height: 20))
              else
                customText(
                  data?.fullName ?? '',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  alight: TextAlign.center,
                ),
              heightBx(h: 4),
              if (loading)
                const Center(child: ShimmerBox(width: 180, height: 14))
              else
                customText(
                  data?.email ?? '',
                  color: AppColors.subTitle,
                  alight: TextAlign.center,
                ),
              heightBx(h: 24),
              _StatsRow(l10n: l10n),
              heightBx(h: 24),
              const _MenuCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;

  const _Avatar({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: _softShadow,
            ),
            child: Center(child: appAvatar(url: avatarUrl, size: 92)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => _showComingSoon(context),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AppLocalizations l10n;

  const _StatsRow({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _softShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.access_time,
                value: "2h 30m",
                label: l10n.workHours,
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _StatItem(
                icon: Icons.beach_access_outlined,
                value: "2",
                label: l10n.leaveDays,
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _StatItem(
                icon: Icons.task_alt,
                value: "12",
                label: l10n.tasksDone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      const VerticalDivider(width: 1, thickness: 1, color: AppColors.border);
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.primaryTint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        heightBx(h: 8),
        customText(value, fontWeight: FontWeight.w700, fontSize: 15),
        heightBx(h: 2),
        customText(label, color: AppColors.subTitle, fontSize: 12),
      ],
    );
  }
}

class _MenuCard extends ConsumerWidget {
  const _MenuCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _MenuRow(
            icon: Icons.person_outline,
            label: l10n.personal,
            onTap: () => _openComingSoon(context, l10n.personal, Icons.person_outline),
          ),
          _menuDivider(),
          _MenuRow(
            icon: Icons.lock_outline,
            label: l10n.changePassword,
            onTap: () => context.push(AppRoutes.changePassword),
          ),
          _menuDivider(),
          // "General" in the reference image — routed to the app's real
          // Settings screen (language switcher today), so it's labeled the
          // same as everywhere else that opens it rather than a new term.
          _MenuRow(
            icon: Icons.tune,
            label: l10n.settings,
            onTap: () => context.push(AppRoutes.settings),
          ),
          _menuDivider(),
          _MenuRow(
            icon: Icons.notifications_outlined,
            label: l10n.notifications,
            onTap: () =>
                _openComingSoon(context, l10n.notifications, Icons.notifications_outlined),
          ),
          _menuDivider(),
          _MenuRow(
            icon: Icons.help_outline,
            label: l10n.help,
            onTap: () => _openComingSoon(context, l10n.help, Icons.help_outline),
          ),
          _menuDivider(),
          _MenuRow(
            icon: Icons.logout,
            label: l10n.logout,
            color: AppColors.error,
            showChevron: false,
            onTap: () => ref.read(authSessionProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool showChevron;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tint, size: 20),
            ),
            widthBx(w: 14),
            Expanded(
              child: customText(label, fontWeight: FontWeight.w600, color: tint),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right, color: AppColors.gray400, size: 22),
          ],
        ),
      ),
    );
  }
}

Widget _menuDivider() =>
    const Divider(height: 1, color: AppColors.gray200, indent: 70, endIndent: 16);

/// Soft ambient shadow shared by the profile cards.
const List<BoxShadow> _softShadow = [
  BoxShadow(
    color: Color(0x0F1E3FCB),
    blurRadius: 20,
    offset: Offset(0, 8),
  ),
];

void _showComingSoon(BuildContext context) {
  AppToast.info(AppLocalizations.of(context)!.comingSoon);
}

void _openComingSoon(BuildContext context, String title, IconData icon) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ComingSoonPage(title: title, icon: icon)),
  );
}
