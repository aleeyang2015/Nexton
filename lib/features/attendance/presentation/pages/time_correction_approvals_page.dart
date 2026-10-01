import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/time_correction_approvals_tab.dart';

/// "ຄຳຮ້ອງແກ້ໄຂເວລາ" on its own screen — a titled header over
/// [TimeCorrectionApprovalsTab], which holds the whole list and its filters.
/// The approvals page shows that same tab beside the leave approvals, so the
/// two entry points can never drift apart.
class TimeCorrectionApprovalsPage extends StatelessWidget {
  const TimeCorrectionApprovalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          body: const Column(
            children: [
              _Header(),
              Expanded(child: TimeCorrectionApprovalsTab()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 4, 15, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          Expanded(
            child: customText(
              l10n.timeCorrectionApprovalsTitle,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
