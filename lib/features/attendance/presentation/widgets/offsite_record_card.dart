import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/offsite_detail.dart';
import 'approval_card_parts.dart';
import 'offsite_request_facts.dart';
import 'time_correction_copy.dart';

/// One of the employee's own off-site scan requests on the history page: when
/// it was filed, its short id and status, the day and shift segment, which
/// punch it stands in for, when and where it was taken, the reason and the
/// photo.
///
/// The approver's [OffsiteApprovalCard] with its two ends swapped: no employee
/// row, because the employee is the one reading, and in place of the approve /
/// reject pair the one action that *is* theirs — withdrawing a request still
/// pending (§9). Everything between is the same widget.
class OffsiteRecordCard extends StatelessWidget {
  final OffsiteRequestDetail request;

  /// Opens the attached photo full-screen.
  final ValueChanged<String> onViewImage;

  /// Withdraws the request. Only ever called for a pending one — the button is
  /// not built otherwise.
  final VoidCallback onCancel;

  /// Whether this request's withdrawal is in flight; disables the button.
  final bool cancelling;

  const OffsiteRecordCard({
    super.key,
    required this.request,
    required this.onViewImage,
    required this.onCancel,
    required this.cancelling,
  });

  @override
  Widget build(BuildContext context) {
    final photo = request.attachmentUrl;

    return ApprovalCardShell(
      children: [
        _MetaRow(request: request),
        heightBx(h: 12),
        OffsiteScanBox(request: request),
        heightBx(h: 12),
        OffsitePositionRow(request: request),
        if (request.reason.isNotEmpty) ...[
          heightBx(h: 12),
          ApprovalReasonLine(reason: request.reason),
        ],
        heightBx(h: 8),
        if (photo == null)
          const ApprovalNoAttachment()
        else
          ApprovalAttachmentRow(url: photo, onView: () => onViewImage(photo)),
        // Only a request nobody has decided on yet can be withdrawn (§9); the
        // endpoint has the last word, and refuses a card that has gone stale.
        if (request.canCancel) ...[
          heightBx(h: 14),
          _CancelButton(loading: cancelling, onTap: onCancel),
        ],
      ],
    );
  }
}

/// "ຍົກເລີກຄຳຮ້ອງ" on a red tint — the same read as the detail page's cancel
/// button, sized for a card in a list.
class _CancelButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _CancelButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: AppColors.danger.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 44,
          width: double.infinity,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.danger,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cancel_outlined,
                        size: 20,
                        color: AppColors.danger,
                      ),
                      widthBx(w: 8),
                      Flexible(
                        child: customText(
                          l10n.offsiteCancelAction,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
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

/// "02/10/2026 08:15 · #a3f1" and the status pill — the history card's top
/// line, where the approver's card carries the employee instead.
class _MetaRow extends StatelessWidget {
  final OffsiteRequestDetail request;

  const _MetaRow({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: customText(
                  TimeCorrectionCopy.submittedAt(request.submittedAt),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTxt,
                ),
              ),
              customText(' · ', fontSize: 12, color: AppColors.gray400),
              customText(
                TimeCorrectionCopy.shortId(request.id),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryVariant,
              ),
            ],
          ),
        ),
        widthBx(w: 6),
        _StatusPill(
          label: TimeCorrectionCopy.statusLabel(l10n, request.status),
          color: TimeCorrectionCopy.statusColor(request.status),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ],
      ),
    );
  }
}
