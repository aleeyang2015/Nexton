import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// "Approve this request?": asks before an approval, with one optional
/// note for the approver to leave (`approver_note`). Shared by every
/// approval of the Approvals place.
///
/// Resolves to the note typed (empty when none) when the approver confirms,
/// or null when they back out.
class ApproveNoteDialog extends StatefulWidget {
  const ApproveNoteDialog({
    super.key,
    this.lastStep = false,
    required this.approveLabel,
  });

  /// The approval decides the request: say what follows (for leave, the
  /// days come off the balance now).
  final bool lastStep;

  /// The confirm button's words ("Approve", or "Approve (final)").
  final String approveLabel;

  static Future<String?> show(
    BuildContext context, {
    bool lastStep = false,
    required String approveLabel,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          ApproveNoteDialog(lastStep: lastStep, approveLabel: approveLabel),
    );
  }

  @override
  State<ApproveNoteDialog> createState() => _ApproveNoteDialogState();
}

class _ApproveNoteDialogState extends State<ApproveNoteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: customText(
        l10n.apprApproveConfirmTitle,
        fontWeight: FontWeight.w700,
        fontSize: 17,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.lastStep) ...[
            customText(
              l10n.apprApproveLastStepHint,
              fontSize: 13,
              color: AppColors.textPrimary,
              maxLine: 4,
            ),
            heightBx(h: 12),
          ],
          TextField(
            controller: _controller,
            maxLines: 3,
            minLines: 2,
            style: AppTextStyles.inputStyle,
            decoration: inputDecoration(l10n.apprApproveNoteHint),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: customText(l10n.cancel, color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: customText(
            widget.approveLabel,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
