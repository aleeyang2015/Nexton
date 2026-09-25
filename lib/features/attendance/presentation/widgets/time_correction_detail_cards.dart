import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/time_correction_detail.dart';
import 'attendance_history_copy.dart';
import 'time_correction_copy.dart';
import 'time_correction_detail_copy.dart';

/// The white rounded card every detail section sits in.
class TimeCorrectionDetailCard extends StatelessWidget {
  final Widget child;

  const TimeCorrectionDetailCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// A section's icon and title, with an optional trailing widget.
class TimeCorrectionSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const TimeCorrectionSectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: AppColors.primaryVariant, size: 22),
        ),
        widthBx(w: 10),
        Expanded(
          child: customText(
            title,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            maxLine: 2,
          ),
        ),
        if (trailing != null) ...[widthBx(w: 8), trailing],
      ],
    );
  }
}

/// A small rounded label — the id chip, the type chip, the OT badge.
class TimeCorrectionTag extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const TimeCorrectionTag({
    super.key,
    required this.label,
    this.color = AppColors.primaryVariant,
    this.background = AppColors.primaryTint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: customText(
        label,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

/// A status pill with a leading dot.
class TimeCorrectionDotPill extends StatelessWidget {
  final String label;
  final Color color;

  const TimeCorrectionDotPill({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          widthBx(w: 6),
          customText(
            label,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ],
      ),
    );
  }
}

/// Short id, submit time and status, over the employee and the day corrected.
class TimeCorrectionSummaryCard extends StatelessWidget {
  final TimeCorrectionDetail detail;

  const TimeCorrectionSummaryCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TimeCorrectionDetailCard(
      child: Column(
        children: [
          Row(
            children: [
              TimeCorrectionTag(
                label: TimeCorrectionCopy.shortId(detail.id),
                color: AppColors.secondaryTxt,
              ),
              widthBx(w: 8),
              Expanded(
                child: customText(
                  l10n.timeCorrectionSubmittedOn(
                    TimeCorrectionDetailCopy.dateTimeSeconds(
                      detail.submittedAt,
                    ),
                  ),
                  fontSize: 13,
                  color: AppColors.secondaryTxt,
                  maxLine: 2,
                ),
              ),
              widthBx(w: 6),
              TimeCorrectionDotPill(
                label: TimeCorrectionCopy.statusLabel(l10n, detail.status),
                color: TimeCorrectionDetailCopy.statusColor(detail.status),
              ),
            ],
          ),
          heightBx(h: 14),
          _EmployeeBox(detail: detail),
        ],
      ),
    );
  }
}

class _EmployeeBox extends StatelessWidget {
  final TimeCorrectionDetail detail;

  const _EmployeeBox({required this.detail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final employee = detail.employee;
    final line = TimeCorrectionDetailCopy.employeeLine(l10n, employee);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: customText(
              TimeCorrectionDetailCopy.initials(employee.name),
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          widthBx(w: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  TimeCorrectionDetailCopy.displayName(employee.name),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                if (line.isNotEmpty)
                  customText(
                    line,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTxt,
                  ),
              ],
            ),
          ),
          widthBx(w: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              customText(
                l10n.timeCorrectionRequestDateLabel,
                fontSize: 11,
                color: AppColors.secondaryTxt,
              ),
              customText(
                AttendanceHistoryCopy.dayMonthYear(l10n, detail.requestDate),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Requested times against the shift's own, total hours, and the shift.
class TimeCorrectionTimesCard extends StatelessWidget {
  final TimeCorrectionDetail detail;

  const TimeCorrectionTimesCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = detail.type;
    final shift = detail.shift;
    final total = detail.requestedDuration;

    return TimeCorrectionDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TimeCorrectionSectionTitle(
            icon: Icons.schedule,
            title: l10n.timeCorrectionDetailsSection,
            trailing: TimeCorrectionTag(
              label: TimeCorrectionCopy.typeLabel(l10n, type),
            ),
          ),
          heightBx(h: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (type.needsClockIn)
                  Expanded(
                    child: _TimeColumn(
                      icon: Icons.login,
                      iconColor: AppColors.attendancePresent,
                      label: l10n.timeCorrectionRequestedIn,
                      time: detail.clockIn,
                      normal: shift?.start,
                    ),
                  ),
                if (type.needsClockOut)
                  Expanded(
                    child: _TimeColumn(
                      icon: Icons.logout,
                      iconColor: AppColors.danger,
                      label: l10n.timeCorrectionRequestedOut,
                      time: detail.clockOut,
                      normal: shift?.end,
                    ),
                  ),
              ],
            ),
          ),
          if (total != null) ...[
            heightBx(h: 16),
            Row(
              children: [
                const Icon(Icons.timelapse, color: AppColors.gray500, size: 22),
                widthBx(w: 8),
                Expanded(
                  child: customText(
                    l10n.timeCorrectionTotalHours,
                    fontSize: 15,
                    color: AppColors.secondaryTxt,
                  ),
                ),
                customText(
                  l10n.timeCorrectionHoursValue(
                    TimeCorrectionDetailCopy.hours(total),
                  ),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryVariant,
                ),
              ],
            ),
          ],
          if (shift != null) ...[heightBx(h: 16), _ShiftBox(shift: shift)],
        ],
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Duration? time;
  final Duration? normal;

  const _TimeColumn({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.time,
    required this.normal,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final time = this.time;
    final normal = this.normal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 18),
            widthBx(w: 6),
            Expanded(
              child: customText(
                label,
                fontSize: 12,
                color: AppColors.secondaryTxt,
                maxLine: 2,
              ),
            ),
          ],
        ),
        heightBx(h: 4),
        customText(
          time == null ? '--:--' : TimeCorrectionCopy.hourMinuteOf(time),
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        if (normal != null)
          customText(
            l10n.timeCorrectionNormalTime(
              TimeCorrectionCopy.hourMinuteOf(normal),
            ),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTxt,
          ),
      ],
    );
  }
}

class _ShiftBox extends StatelessWidget {
  final TimeCorrectionShift shift;

  const _ShiftBox({required this.shift});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = TimeCorrectionDetailCopy.shiftName(l10n, shift);
    final hours = TimeCorrectionDetailCopy.shiftHours(shift);
    final breakMinutes = shift.breakMinutes;
    final type = TimeCorrectionDetailCopy.shiftType(l10n, shift);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: customText(
                  l10n.timeCorrectionShiftGroup,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTxt,
                ),
              ),
              if (shift.overtimeEligible)
                TimeCorrectionTag(
                  label: l10n.timeCorrectionOtEligible,
                  color: const Color(0xFF15803D),
                  background: const Color(0xFF86EFAC),
                ),
            ],
          ),
          heightBx(h: 8),
          Row(
            children: [
              if (name != null)
                Expanded(
                  child: customText(
                    name,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              if (hours != null)
                customText(
                  breakMinutes == null || breakMinutes == 0
                      ? hours
                      : l10n.timeCorrectionShiftBreak(hours, breakMinutes),
                  fontSize: 13,
                  color: AppColors.secondaryTxt,
                ),
            ],
          ),
          if (type != null) ...[
            heightBx(h: 8),
            customText(
              l10n.timeCorrectionShiftType(type),
              fontSize: 13,
              color: AppColors.secondaryTxt,
              maxLine: 2,
            ),
          ],
        ],
      ),
    );
  }
}

/// The employee's reason, quoted.
class TimeCorrectionReasonCard extends StatelessWidget {
  final String reason;

  const TimeCorrectionReasonCard({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TimeCorrectionDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TimeCorrectionSectionTitle(
            icon: Icons.description_outlined,
            title: l10n.timeCorrectionReasonSection,
          ),
          heightBx(h: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '"$reason"',
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The evidence file: a thumbnail, its name and kind, and view / download.
class TimeCorrectionAttachmentCard extends StatelessWidget {
  final String url;
  final bool downloading;
  final VoidCallback onView;
  final VoidCallback onDownload;

  const TimeCorrectionAttachmentCard({
    super.key,
    required this.url,
    required this.downloading,
    required this.onView,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final image = TimeCorrectionDetailCopy.isImage(url);

    return TimeCorrectionDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TimeCorrectionSectionTitle(
            icon: Icons.attach_file,
            title: l10n.timeCorrectionAttachmentsSection,
            trailing: customText(
              l10n.timeCorrectionFileCount(1),
              fontSize: 12,
              color: AppColors.secondaryTxt,
            ),
          ),
          heightBx(h: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _Thumbnail(url: url, image: image),
                widthBx(w: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      customText(
                        TimeCorrectionDetailCopy.fileName(url),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      customText(
                        image
                            ? l10n.timeCorrectionEvidencePhoto
                            : l10n.timeCorrectionEvidenceDocument,
                        fontSize: 13,
                        color: AppColors.secondaryTxt,
                      ),
                    ],
                  ),
                ),
                if (image) ...[
                  widthBx(w: 8),
                  _SquareButton(icon: Icons.visibility_outlined, onTap: onView),
                ],
                widthBx(w: 8),
                _SquareButton(
                  icon: Icons.download,
                  onTap: downloading ? null : onDownload,
                  busy: downloading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String url;
  final bool image;

  const _Thumbnail({required this.url, required this.image});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Icon(
        image ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
        color: AppColors.gray500,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image)
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              )
            else
              fallback,
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                color: AppColors.primaryDark,
                child: customText(
                  TimeCorrectionDetailCopy.extension(url),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool busy;

  const _SquareButton({required this.icon, this.onTap, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, color: AppColors.primaryVariant, size: 22),
        ),
      ),
    );
  }
}
