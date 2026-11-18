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
import '../../../../features/attendance/domain/entities/attendance_summary.dart';
import '../../../../features/attendance/presentation/providers/attendance_month_summary_notifier.dart';
import '../../../../features/auth/presentation/providers/auth_session_notifier.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../profile_error_copy.dart';
import '../providers/profile_notifier.dart';
import '../providers/profile_photo_notifier.dart';
import '../../../../core/upload/presentation/file_source_sheet.dart';
import '../../../../core/upload/domain/capture_policy.dart';
import '../../../../core/l10n/failure_localizer.dart';

/// "ໂປຣຟາຍ" screen, pushed from the home header. Profile summary + a
/// settings-style menu.
///
/// Identity and photo come from [profileNotifierProvider]. When that load
/// fails, a message card stands in for the name and email and says why
/// ([profileErrorCopy]); the menu stays usable, so the user can still change
/// the password or sign out.
///
/// The stats row shows this month's real hours worked, late arrivals and
/// absences from [attendanceMonthSummaryNotifierProvider]
/// (`GET /attendance/records/summary/my`). The numbers are the server's; when
/// that load fails the row shows a dash, never a `0` that would read as real.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileNotifierProvider);
    final loading = profile.isLoading && !profile.hasValue;
    final error = profile.hasError ? profile.error : null;
    final data = profile.valueOrNull;

    return Container(
      color: AppColors.homeBackground,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          body: Column(
            children: [
              // Outside the list so it stays put while the content scrolls.
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _TopBar(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  children: [
                    Center(
                      child: _Avatar(
                        avatarUrl: data?.avatarUrl,
                        // No employee id before the profile loads: nothing
                        // to change yet (#59).
                        canChange: data != null,
                      ),
                    ),
                    heightBx(h: 16),
                    if (loading) ...[
                      const Center(child: ShimmerBox(width: 140, height: 20)),
                      heightBx(h: 4),
                      const Center(child: ShimmerBox(width: 180, height: 14)),
                    ] else if (error != null)
                      // In place of the name and email: an empty name would
                      // say nothing about what went wrong.
                      _ProfileLoadError(
                        copy: profileErrorCopy(
                          AppLocalizations.of(context)!,
                          error,
                        ),
                        onRetry: () => ref
                            .read(profileNotifierProvider.notifier)
                            .refresh(),
                      )
                    else ...[
                      _NameRow(name: data?.fullName ?? ''),
                      heightBx(h: 4),
                      customText(
                        data?.email ?? '',
                        color: AppColors.subTitle,
                        fontSize: 14,
                        alight: TextAlign.center,
                      ),
                    ],
                    heightBx(h: 12),
                    const Center(child: _StatusPill()),
                    heightBx(h: 20),
                    const _StatsRow(),
                    heightBx(h: 16),
                    const _MenuCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round white back button, centered blue title, round "more" button.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        _RoundButton(icon: Icons.chevron_left, onTap: () => context.pop()),
        Expanded(
          child: customText(
            l10n.profile,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            alight: TextAlign.center,
          ),
        ),
        _RoundButton(
          icon: Icons.more_horiz,
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: _softShadow,
        ),
        child: Icon(icon, size: 22, color: AppColors.textPrimary),
      ),
    );
  }
}

/// The card shown where the name and email would be when the profile could
/// not be loaded: why, and a Retry only when trying again can help.
class _ProfileLoadError extends StatelessWidget {
  final ({String text, bool canRetry}) copy;
  final VoidCallback onRetry;

  const _ProfileLoadError({required this.copy, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _softShadow,
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 24),
          heightBx(h: 8),
          customText(
            copy.text,
            color: AppColors.textPrimary,
            fontSize: 14,
            maxLine: 4,
            alight: TextAlign.center,
          ),
          if (copy.canRetry) ...[
            heightBx(h: 10),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onRetry,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: customText(
                  l10n.retry,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full name followed by a small blue verified check.
class _NameRow extends StatelessWidget {
  final String name;

  const _NameRow({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: customText(
            name,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            alight: TextAlign.center,
          ),
        ),
        widthBx(w: 6),
        const Icon(Icons.verified, size: 18, color: AppColors.secondary),
      ],
    );
  }
}

/// Green "Active" pill under the email.
class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const color = AppColors.attendancePresent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          widthBx(w: 6),
          customText(
            l10n.profileStatusActive,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ],
      ),
    );
  }
}

/// The photo, and its pencil (#59): camera, gallery or an image file. While
/// a new photo is on its way the avatar shows a spinner and the pencil is
/// off; a toast says how it went.
class _Avatar extends ConsumerWidget {
  final String? avatarUrl;
  final bool canChange;

  const _Avatar({required this.avatarUrl, required this.canChange});

  Future<void> _change(BuildContext context, WidgetRef ref) async {
    final picked = await FileSourceSheet.pick(
      context,
      ref,
      CapturePolicy.photo,
    );
    await ref.read(profilePhotoNotifierProvider.notifier).accept(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final uploading = ref.watch(
      profilePhotoNotifierProvider.select((s) => s.uploading),
    );
    ref.listen(profilePhotoNotifierProvider, (_, next) {
      switch (next.status) {
        case ProfilePhotoStatus.done:
          AppToast.success(l10n.profilePhotoChanged);
        case ProfilePhotoStatus.failed:
          final failure = next.failure;
          if (failure != null) AppToast.error(failure.localize(l10n));
        case ProfilePhotoStatus.idle || ProfilePhotoStatus.uploading:
          break;
      }
    });

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, AppColors.primaryTint],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: uploading
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : appAvatar(url: avatarUrl, size: 96),
            ),
          ),
          if (canChange)
            Positioned(
              right: 2,
              bottom: 2,
              child: GestureDetector(
                onTap: uploading ? null : () => _change(context, ref),
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

/// This month's hours worked, late arrivals and absences, from
/// `GET /attendance/records/summary/my`.
class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summary = ref.watch(attendanceMonthSummaryNotifierProvider);
    final loading = summary.isLoading && !summary.hasValue;
    final data = summary.valueOrNull;

    // Null shows the shimmer while loading and a dash if there's no data,
    // rather than a "0" that would read as a real result.
    String? show(String Function(AttendanceSummary) format) =>
        loading ? null : (data == null ? '-' : format(data));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
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
                color: AppColors.primary,
                value: show((d) => d.totalWorkHours.toStringAsFixed(1)),
                label: l10n.workHours,
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _StatItem(
                icon: Icons.alarm,
                color: AppColors.attendanceLate,
                value: show((d) => '${d.lateDays}'),
                label: l10n.lateArrivals,
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _StatItem(
                icon: Icons.person_off_outlined,
                color: AppColors.attendanceAbsent,
                value: show((d) => '${d.absentDays}'),
                label: l10n.absences,
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
  Widget build(BuildContext context) => const VerticalDivider(
    width: 1,
    thickness: 1,
    indent: 18,
    endIndent: 18,
    color: AppColors.gray200,
  );
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;

  /// Null while loading, which shows a placeholder in its place.
  final String? value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.color,
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
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        heightBx(h: 8),
        if (value == null)
          const ShimmerBox(width: 28, height: 16)
        else
          customText(
            value!,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        heightBx(h: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: customText(
            label,
            color: AppColors.subTitle,
            fontSize: 12,
            maxLine: 2,
            alight: TextAlign.center,
          ),
        ),
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
            color: AppColors.primary,
            label: l10n.personal,
            onTap: () => context.push(AppRoutes.personalInfo),
          ),
          _menuDivider(),
          _MenuRow(
            icon: Icons.lock_outline,
            color: _purple,
            label: l10n.changePassword,
            onTap: () => context.push(AppRoutes.changePassword),
          ),
          _menuDivider(),
          // "General" in the reference image — routed to the app's real
          // Settings screen (language switcher today), so it's labeled the
          // same as everywhere else that opens it rather than a new term.
          _MenuRow(
            icon: Icons.tune,
            color: AppColors.info,
            label: l10n.settings,
            onTap: () => context.push(AppRoutes.settings),
          ),
          _menuDivider(),
          _MenuRow(
            icon: Icons.notifications_outlined,
            color: AppColors.warning,
            label: l10n.notifications,
            onTap: () => context.push(AppRoutes.notifications),
          ),
          _menuDivider(),
          _MenuRow(
            icon: Icons.help_outline,
            color: _teal,
            label: l10n.help,
            onTap: () =>
                _openComingSoon(context, l10n.help, Icons.help_outline),
          ),
          _menuDivider(),
          _MenuRow(
            icon: Icons.logout,
            label: l10n.logout,
            color: AppColors.danger,
            destructive: true,
            onTap: () => ref.read(authSessionProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  /// Red label and chevron, for the sign-out row.
  final bool destructive;

  const _MenuRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            widthBx(w: 14),
            Expanded(
              child: customText(
                label,
                fontWeight: FontWeight.w600,
                color: destructive ? color : AppColors.textPrimary,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: destructive
                  ? color.withValues(alpha: 0.5)
                  : AppColors.gray400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _menuDivider() => const Divider(height: 1, color: AppColors.gray200);

// Accent colors for the stat and menu icons that the shared palette has no
// name for.
const Color _purple = Color(0xFF6C5CE7);
const Color _teal = Color(0xFF14B8A6);

/// Soft ambient shadow shared by the profile cards.
const List<BoxShadow> _softShadow = [
  BoxShadow(color: Color(0x0F1E3FCB), blurRadius: 20, offset: Offset(0, 8)),
];

void _showComingSoon(BuildContext context) {
  AppToast.info(AppLocalizations.of(context)!.comingSoon);
}

void _openComingSoon(BuildContext context, String title, IconData icon) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ComingSoonPage(title: title, icon: icon),
    ),
  );
}
