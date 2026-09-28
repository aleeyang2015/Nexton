import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/time_correction_detail.dart';
import '../../domain/entities/time_correction_status.dart';
import 'time_correction_approval_copy.dart';
import 'time_correction_copy.dart';
import 'time_correction_detail_cards.dart';
import 'time_correction_detail_copy.dart';

/// One request on the approvals page: who filed it and its status, the day,
/// shift and correction type, the requested time(s), the reason, the
/// evidence file, and — while it is pending — the approve / reject buttons.
class TimeCorrectionApprovalCard extends StatelessWidget {
  final TimeCorrectionDetail request;

  /// Whether a decision on this request is in flight; disables the buttons.
  final bool deciding;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final ValueChanged<String> onViewImage;

  const TimeCorrectionApprovalCard({
    super.key,
    required this.request,
    required this.deciding,
    required this.onApprove,
    required this.onReject,
    required this.onViewImage,
  });

  @override
  Widget build(BuildContext context) {
    final attachment = request.attachmentUrl;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EmployeeRow(request: request),
          heightBx(h: 14),
          _ScheduleBox(request: request),
          heightBx(h: 12),
          _TimeTiles(request: request),
          if (request.reason.isNotEmpty) ...[
            heightBx(h: 12),
            _ReasonLine(reason: request.reason),
          ],
          heightBx(h: 8),
          if (attachment == null)
            const _NoAttachment()
          else
            _AttachmentRow(
              url: attachment,
              onView: () => onViewImage(attachment),
            ),
          if (request.status == TimeCorrectionStatus.pending) ...[
            heightBx(h: 14),
            _DecisionRow(
              enabled: !deciding,
              onApprove: onApprove,
              onReject: onReject,
            ),
          ],
        ],
      ),
    );
  }
}

/// Initials, name, employee-number tag and department, with the status pill
/// on the right.
class _EmployeeRow extends StatelessWidget {
  final TimeCorrectionDetail request;

  const _EmployeeRow({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final employee = request.employee;
    final number = employee.employeeNumber;
    final department = TimeCorrectionApprovalCopy.department(l10n, employee);
    final status = TimeCorrectionApprovalCopy.status(l10n, request.status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: customText(
            TimeCorrectionDetailCopy.initials(employee.name),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        widthBx(w: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: customText(
                      employee.name,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (number != null) ...[
                    widthBx(w: 8),
                    TimeCorrectionTag(label: number),
                  ],
                ],
              ),
              if (department != null) ...[
                heightBx(h: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.apartment,
                      size: 15,
                      color: AppColors.gray500,
                    ),
                    widthBx(w: 4),
                    Flexible(
                      child: customText(
                        department,
                        fontSize: 13,
                        color: AppColors.secondaryTxt,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        widthBx(w: 8),
        TimeCorrectionDotPill(label: status.label, color: status.color),
      ],
    );
  }
}

/// The corrected day and its shift segment, over the correction-type chip
/// and the shift group.
class _ScheduleBox extends StatelessWidget {
  final TimeCorrectionDetail request;

  const _ScheduleBox({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final segment = TimeCorrectionApprovalCopy.shiftSegment(
      l10n,
      request.shift,
    );
    final group = TimeCorrectionApprovalCopy.shiftGroup(l10n, request.shift);
    final type = TimeCorrectionApprovalCopy.type(l10n, request.type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.primaryVariant,
              ),
              widthBx(w: 8),
              Expanded(
                child: customText(
                  TimeCorrectionApprovalCopy.date(request.requestDate),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (segment != null) ...[
                widthBx(w: 8),
                Flexible(child: _OutlinedChip(label: segment)),
              ],
            ],
          ),
          heightBx(h: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _TintedChip(
                icon: type.icon,
                label: type.label,
                color: type.color,
              ),
              if (group != null)
                _TintedChip(label: group, color: AppColors.primaryVariant),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutlinedChip extends StatelessWidget {
  final String label;

  const _OutlinedChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.gray300),
      ),
      child: customText(
        label,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _TintedChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;

  const _TintedChip({this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            widthBx(w: 4),
          ],
          customText(
            label,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ],
      ),
    );
  }
}

/// The in / out tiles side by side. A side the request corrects shows the
/// requested time on a tint; the other side stays white with "-- : --".
class _TimeTiles extends StatelessWidget {
  final TimeCorrectionDetail request;

  const _TimeTiles({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = request.type;

    return Row(
      children: [
        Expanded(
          child: _TimeTile(
            requested: type.needsClockIn,
            label: type.needsClockIn
                ? l10n.timeCorrectionApprovalNewIn
                : l10n.timeCorrectionApprovalClockIn,
            icon: Icons.login,
            time: type.needsClockIn ? request.clockIn : null,
          ),
        ),
        widthBx(w: 10),
        Expanded(
          child: _TimeTile(
            requested: type.needsClockOut,
            label: type.needsClockOut
                ? l10n.timeCorrectionApprovalNewOut
                : l10n.timeCorrectionApprovalClockOut,
            icon: Icons.logout,
            time: type.needsClockOut ? request.clockOut : null,
          ),
        ),
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  final bool requested;
  final String label;
  final IconData icon;
  final Duration? time;

  const _TimeTile({
    required this.requested,
    required this.label,
    required this.icon,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final time = this.time;
    final color = requested ? AppColors.primaryDark : AppColors.gray500;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: requested ? const Color(0xFFF6F7FE) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: requested ? Colors.transparent : AppColors.gray200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          customText(
            label,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: requested ? AppColors.primaryVariant : AppColors.gray600,
          ),
          heightBx(h: 4),
          Row(
            children: [
              if (requested) ...[
                Icon(icon, size: 18, color: color),
                widthBx(w: 6),
              ],
              customText(
                time == null
                    ? '-- : --'
                    : TimeCorrectionCopy.hourMinuteOf(time),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "ເຫດຜົນ: "tssee66"".
class _ReasonLine extends StatelessWidget {
  final String reason;

  const _ReasonLine({required this.reason});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${l10n.timeCorrectionApprovalReason} ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          TextSpan(
            text: '"$reason"',
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _NoAttachment extends StatelessWidget {
  const _NoAttachment();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        const Icon(Icons.link_off, size: 16, color: AppColors.gray400),
        widthBx(w: 6),
        customText(
          l10n.timeCorrectionApprovalNoAttachment,
          fontSize: 13,
          color: AppColors.gray500,
        ),
      ],
    );
  }
}

/// The evidence file: thumbnail, name and kind, with a "ເບິ່ງຮູບ" button
/// for an image.
class _AttachmentRow extends StatelessWidget {
  final String url;
  final VoidCallback onView;

  const _AttachmentRow({required this.url, required this.onView});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final image = TimeCorrectionDetailCopy.isImage(url);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: image
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _FileIcon(image: true),
                    )
                  : const _FileIcon(image: false),
            ),
          ),
          widthBx(w: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  TimeCorrectionDetailCopy.fileName(url),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                customText(
                  l10n.timeCorrectionApprovalAttachmentSubtitle,
                  fontSize: 12,
                  color: AppColors.secondaryTxt,
                ),
              ],
            ),
          ),
          if (image) ...[
            widthBx(w: 8),
            OutlinedButton.icon(
              onPressed: onView,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryVariant,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.gray300),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: customText(
                l10n.timeCorrectionApprovalViewImage,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FileIcon extends StatelessWidget {
  final bool image;

  const _FileIcon({required this.image});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Icon(
        image ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
        color: AppColors.gray500,
      ),
    );
  }
}

/// "ປະຕິເສດ" on a red tint, "ອະນຸມັດ" filled navy.
class _DecisionRow extends StatelessWidget {
  final bool enabled;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _DecisionRow({
    required this.enabled,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _DecisionButton(
            label: l10n.timeCorrectionApprovalReject,
            icon: Icons.close,
            background: AppColors.danger.withValues(alpha: 0.1),
            foreground: AppColors.danger,
            enabled: enabled,
            onTap: onReject,
          ),
        ),
        widthBx(w: 10),
        Expanded(
          child: _DecisionButton(
            label: l10n.timeCorrectionApprovalApprove,
            icon: Icons.check_circle_outline,
            background: AppColors.primaryDark,
            foreground: Colors.white,
            enabled: enabled,
            onTap: onApprove,
          ),
        ),
      ],
    );
  }
}

class _DecisionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final bool enabled;
  final VoidCallback onTap;

  const _DecisionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? background : AppColors.gray200,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 50,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: enabled ? foreground : AppColors.gray500,
                ),
                widthBx(w: 8),
                Flexible(
                  child: customText(
                    label,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: enabled ? foreground : AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
