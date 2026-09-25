import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/time_correction_record.dart';
import 'attendance_history_copy.dart';
import 'time_correction_copy.dart';

/// One filed request on the history page: when it was sent, its short id and
/// status, the corrected day, the correction type and time(s), and how many
/// files it carries.
class TimeCorrectionRecordCard extends StatelessWidget {
  final TimeCorrectionRecord record;
  final VoidCallback? onTap;

  const TimeCorrectionRecordCard({super.key, required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final times = TimeCorrectionCopy.recordTimes(l10n, record);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.edit_calendar_outlined,
                color: AppColors.primaryVariant,
                size: 24,
              ),
            ),
            widthBx(w: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetaRow(record: record),
                  heightBx(h: 6),
                  customText(
                    AttendanceHistoryCopy.dayMonthYear(l10n, record.workDate),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  heightBx(h: 8),
                  // One row, as in the design: the chip gives way (wrapping
                  // its label) so the times and attachment count stay put.
                  Row(
                    children: [
                      Flexible(
                        child: _TypeChip(
                          label: TimeCorrectionCopy.typeLabel(
                            l10n,
                            record.type,
                          ),
                        ),
                      ),
                      if (times != null) ...[
                        widthBx(w: 6),
                        _TimesLabel(icon: times.icon, label: times.label),
                      ],
                      if (record.attachmentCount > 0) ...[
                        widthBx(w: 6),
                        _AttachmentCount(count: record.attachmentCount),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "24/09/2026 10:45 · #d290" and the status pill.
class _MetaRow extends StatelessWidget {
  final TimeCorrectionRecord record;

  const _MetaRow({required this.record});

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
                  TimeCorrectionCopy.submittedAt(record.submittedAt),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTxt,
                ),
              ),
              customText(' · ', fontSize: 12, color: AppColors.gray400),
              customText(
                TimeCorrectionCopy.shortId(record.id),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryVariant,
              ),
            ],
          ),
        ),
        widthBx(w: 6),
        _StatusPill(
          label: TimeCorrectionCopy.statusLabel(l10n, record.status),
          color: TimeCorrectionCopy.statusColor(record.status),
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

class _TypeChip extends StatelessWidget {
  final String label;

  const _TypeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(4),
      ),
      child: customText(
        label,
        fontSize: 12,
        color: AppColors.secondaryTxt,
        maxLine: 2,
      ),
    );
  }
}

class _TimesLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TimesLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.primaryVariant),
        widthBx(w: 4),
        customText(
          label,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryVariant,
        ),
      ],
    );
  }
}

class _AttachmentCount extends StatelessWidget {
  final int count;

  const _AttachmentCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.attach_file, size: 16, color: AppColors.gray500),
        widthBx(w: 2),
        customText('$count', fontSize: 13, color: AppColors.gray600),
      ],
    );
  }
}
