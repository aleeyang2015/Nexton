import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_request.dart';
import '../providers/leave_pending_request_notifier.dart';
import 'leave_request_form.dart';

/// "ຂໍລາພັກ" — the new-leave-request tab. All of the form lives in the shared
/// [LeaveRequestForm] (the edit page reuses it); this tab hosts the
/// `null`-keyed instance.
///
/// While the employee already has a request waiting for a decision, the
/// server refuses a new one. The tab says so above the form, links to the
/// waiting request, and keeps Submit off, so nobody fills the form in only
/// to be refused.
class LeaveRequestTab extends ConsumerWidget {
  const LeaveRequestTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = ref
        .watch(leavePendingRequestNotifierProvider)
        .valueOrNull;

    return LeaveRequestForm(
      header: waiting == null ? null : _WaitingBanner(request: waiting),
      submitBlocked: waiting != null,
    );
  }
}

class _WaitingBanner extends StatelessWidget {
  final LeaveRequest request;

  const _WaitingBanner({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.hourglass_top_outlined,
                size: 18,
                color: AppColors.warning,
              ),
              widthBx(w: 8),
              Expanded(
                child: customText(
                  l10n.leaveRequestPendingBanner,
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                  maxLine: 5,
                ),
              ),
            ],
          ),
          heightBx(h: 6),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => context.push(
                AppRoutes.timeOffRequest(request.id),
                extra: request,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: customText(
                  l10n.leaveViewRequest,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
