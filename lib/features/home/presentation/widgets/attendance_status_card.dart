import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/slide_action_button.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Today's attendance window, as shown on [AttendanceStatusCard].
class AttendanceStatus {
  final bool clockedIn;
  final String clockInTime;
  final String clockOutTime;

  /// Time the clock-in window opens, e.g. "16:00". Only shown while
  /// [clockedIn] is false.
  final String opensAt;
  final List<String> methods;

  const AttendanceStatus({
    required this.clockedIn,
    required this.clockInTime,
    required this.clockOutTime,
    required this.opensAt,
    required this.methods,
  });
}

/// Home screen attendance card: status line, the day's clock-in/out window,
/// a slide-to-confirm action, and the accepted clock-in methods.
///
/// Hardcoded until a clock/attendance feature exists — same convention as
/// [HomePage]'s other placeholder data.
class AttendanceStatusCard extends StatelessWidget {
  final AttendanceStatus status;
  final FutureOr<void> Function()? onSlideComplete;

  const AttendanceStatusCard({
    super.key,
    required this.status,
    this.onSlideComplete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = status.clockedIn ? AppColors.success : AppColors.warning;
    final methodsLabel = _methodLabels(l10n, status.methods).join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              widthBx(w: 8),
              Expanded(
                child: customText(
                  status.clockedIn ? l10n.checkedInStatus : l10n.notCheckedIn,
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          if (!status.clockedIn) ...[
            heightBx(h: 4),
            customText(
              l10n.clockInOpensAt(status.opensAt),
              color: AppColors.secondary,
              fontSize: 13,
            ),
          ],
          heightBx(h: 16),
          Row(
            children: [
              Expanded(child: _TimeColumn(label: l10n.timeIn, time: status.clockInTime)),
              const Icon(Icons.chevron_right, color: AppColors.gray400),
              Expanded(child: _TimeColumn(label: l10n.timeOut, time: status.clockOutTime)),
            ],
          ),
          heightBx(h: 20),
          SlideActionButton(
            label: l10n.slideToClockIn,
            onComplete: onSlideComplete ?? () {},
            resetAfterComplete: true,
          ),
          heightBx(h: 16),
          const Divider(height: 1, color: AppColors.border),
          heightBx(h: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: AppColors.gray500),
              widthBx(w: 8),
              Expanded(
                child: customText(
                  l10n.clockMethodsLabel(methodsLabel),
                  color: AppColors.subTitle,
                  fontSize: 12,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.gray500),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _methodLabels(AppLocalizations l10n, List<String> methods) {
    return methods.map((m) {
      switch (m) {
        case 'gps':
          return l10n.methodGps;
        case 'wifi':
          return l10n.methodWifi;
        case 'biometric':
          return l10n.methodBiometric;
        case 'field':
          return l10n.methodField;
        default:
          return m;
      }
    }).toList(growable: false);
  }
}

class _TimeColumn extends StatelessWidget {
  final String label;
  final String time;

  const _TimeColumn({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        customText(label, color: AppColors.subTitle, fontSize: 13),
        heightBx(h: 4),
        customText(time, fontWeight: FontWeight.w700, fontSize: 30),
      ],
    );
  }
}
