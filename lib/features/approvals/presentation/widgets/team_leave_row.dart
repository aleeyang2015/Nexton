import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../time_off/domain/entities/leave_request.dart';
import '../../../time_off/domain/entities/leave_type.dart';
import '../../../time_off/presentation/providers/leave_types_notifier.dart';
import '../../../time_off/presentation/widgets/leave_copy.dart';

/// One leave request on "My team" (#50), read-only: who, the type (its Lao
/// name), the days ("1, 15 Sep" when not in a row) and the status. A tap
/// opens it ([onTap]).
class TeamLeaveRow extends ConsumerWidget {
  const TeamLeaveRow({super.key, required this.request, this.onTap});

  final LeaveRequest request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final types =
        ref.watch(leaveTypesNotifierProvider).valueOrNull ??
        const <LeaveType>[];
    final pill = LeaveCopy.statusPill(l10n, request.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: customText(
                        request.employeeName,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    widthBx(w: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pill.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: customText(
                        pill.label,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: pill.color,
                      ),
                    ),
                  ],
                ),
                heightBx(h: 6),
                customText(
                  LeaveCopy.leaveTypeLabel(
                    l10n,
                    request.leaveType,
                    types: types,
                  ),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                heightBx(h: 4),
                customText(
                  LeaveCopy.teamDays(l10n, request),
                  fontSize: 13,
                  color: AppColors.subTitle,
                  maxLine: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
