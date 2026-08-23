import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/coming_soon_page.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../features/auth/presentation/providers/auth_session_notifier.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// "ໂປຣຟາຍ" tab. Profile summary + a settings-style menu.
///
/// The identity, photo and stats are placeholder until this feature has a
/// real data source — same convention as [HomePage]'s `_placeholderStats`,
/// and deliberately the same dummy person shown there.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
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
              const Center(child: _Avatar()),
              heightBx(h: 16),
              customText(
                "ໝ່ຳ ຈົກມົກ",
                fontSize: 20,
                fontWeight: FontWeight.w700,
                alight: TextAlign.center,
              ),
              heightBx(h: 4),
              customText(
                "mang.jokmok@nexton.la",
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
  const _Avatar();

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
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: ClipOval(
              child: assetImg(
                "assets/images/mum_jokmok.jpeg",
                width: 112,
                height: 112,
              ),
            ),
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
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: Icons.access_time,
            value: "2h 30m",
            label: l10n.workHours,
          ),
        ),
        Expanded(
          child: _StatItem(
            icon: Icons.beach_access_outlined,
            value: "2",
            label: l10n.leaveDays,
          ),
        ),
        Expanded(
          child: _StatItem(
            icon: Icons.task_alt,
            value: "12",
            label: l10n.tasksDone,
          ),
        ),
      ],
    );
  }
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
            color: AppColors.gray100,
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
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _MenuRow(
            icon: Icons.person_outline,
            label: l10n.personal,
            onTap: () => _openComingSoon(context, l10n.personal, Icons.person_outline),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: tint, size: 22),
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
    const Divider(height: 1, color: AppColors.border, indent: 20, endIndent: 20);

void _showComingSoon(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
}

void _openComingSoon(BuildContext context, String title, IconData icon) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ComingSoonPage(title: title, icon: icon)),
  );
}
