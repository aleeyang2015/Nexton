import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'time_correction_detail_cards.dart';
import 'time_correction_detail_copy.dart';

/// The pieces every approval card is built from, shared by the time-correction
/// and off-site tabs so the two lists read as one screen.
///
/// Each one takes plain values rather than a request object: the two workflows
/// answer with different shapes, and the only thing that would come of passing
/// either of them here is a parts file that has to know about both.

/// Initials, name, employee-number tag and department, with the status pill on
/// the right.
class ApprovalEmployeeRow extends StatelessWidget {
  final String name;
  final String? employeeNumber;

  /// Already prefixed ("ພະແນກ: …"), or null when the employee has none.
  final String? department;

  final String statusLabel;
  final Color statusColor;

  const ApprovalEmployeeRow({
    super.key,
    required this.name,
    required this.employeeNumber,
    required this.department,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final number = employeeNumber;
    final departmentName = department;

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
            TimeCorrectionDetailCopy.initials(name),
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
                      name,
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
              if (departmentName != null) ...[
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
                        departmentName,
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
        TimeCorrectionDotPill(label: statusLabel, color: statusColor),
      ],
    );
  }
}

/// A white pill with a hairline border — the shift segment on a card's date row.
class ApprovalOutlinedChip extends StatelessWidget {
  final String label;

  const ApprovalOutlinedChip({super.key, required this.label});

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

/// A chip on a tint of its own colour — the request's type, the shift group.
class ApprovalTintedChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;

  const ApprovalTintedChip({
    super.key,
    this.icon,
    required this.label,
    required this.color,
  });

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

/// 'ເຫດຜົນ: "tssee66"'.
class ApprovalReasonLine extends StatelessWidget {
  final String reason;

  const ApprovalReasonLine({super.key, required this.reason});

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

class ApprovalNoAttachment extends StatelessWidget {
  const ApprovalNoAttachment({super.key});

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

/// The attached file: thumbnail, name and kind, with a "ເບິ່ງຮູບ" button for an
/// image.
class ApprovalAttachmentRow extends StatelessWidget {
  final String url;
  final VoidCallback onView;

  const ApprovalAttachmentRow({
    super.key,
    required this.url,
    required this.onView,
  });

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
class ApprovalDecisionRow extends StatelessWidget {
  final bool enabled;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const ApprovalDecisionRow({
    super.key,
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

/// The card shell both approval cards sit in.
class ApprovalCardShell extends StatelessWidget {
  final List<Widget> children;

  const ApprovalCardShell({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
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
        children: children,
      ),
    );
  }
}
