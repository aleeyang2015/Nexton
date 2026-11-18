import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/error_page.dart';
import '../../core/widgets/global_widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../attendance/presentation/widgets/offsite_approvals_tab.dart';
import '../attendance/presentation/widgets/time_correction_approvals_tab.dart';
import '../overtime/presentation/widgets/ot_approvals_tab.dart';
import '../time_off/presentation/widgets/leave_approvals_badge_icon.dart';
import '../time_off/presentation/widgets/leave_approvals_tab.dart';
import 'domain/approver_access.dart';
import 'presentation/providers/approver_access_provider.dart';
import 'presentation/widgets/team_tab.dart';

/// The sections of [ApprovalsPage], in tab order.
enum ApprovalsTab {
  leave,
  timeCorrection,
  offsite,
  ot,
  team;

  /// The sections [access] may see, in tab order: leave for leave approvers,
  /// "forgot to scan" and off-site for attendance approvers, OT for heads
  /// (#48: the App does not decide OT's HR steps).
  static List<ApprovalsTab> visibleFor(ApproverAccess access) => [
    if (access.canApproveLeave) leave,
    if (access.canApproveAttendance) ...[timeCorrection, offsite],
    if (access.canApproveOt) ot,
    if (access.canSeeTeam) team,
  ];
}

/// "ອະນຸມັດ" — everything waiting on the signed-in approver, gathered behind
/// the home menu's single approvals tile: the leave requests
/// ([LeaveApprovalsTab], the same tab [TimeOffPage] shows), the time-correction
/// requests ([TimeCorrectionApprovalsTab]) and the off-site scan requests
/// ([OffsiteApprovalsTab]).
///
/// For department heads and HR only (decision 8), and each section only for
/// those who may decide it ([ApprovalsTab.visibleFor]). With one section the
/// tab bar still shows, so the place looks the same as more arrive. The
/// sections can change while the page is open (`/auth/me` read again on
/// resume): [DefaultTabController] follows the new count.
///
/// Each tab is the feature's own widget rather than a copy, so a change to
/// a list shows up here and on its own screen at once. Each one owns its
/// provider, its filters and its empty / failed states; this page only holds
/// the chrome.
class ApprovalsPage extends ConsumerWidget {
  const ApprovalsPage({super.key, this.initialTab = ApprovalsTab.leave});

  final ApprovalsTab initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ApprovalsTab.visibleFor(ref.watch(approverAccessProvider));
    if (tabs.isEmpty) return const NotFoundPage();
    final initial = tabs.indexOf(initialTab);

    return DefaultTabController(
      length: tabs.length,
      initialIndex: initial < 0 ? 0 : initial,
      child: _ApprovalsScaffold(tabs: tabs),
    );
  }
}

class _ApprovalsScaffold extends StatelessWidget {
  const _ApprovalsScaffold({required this.tabs});

  final List<ApprovalsTab> tabs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: customText(
              l10n.approvalsMenu,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 20,
            ),
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Icon(Icons.arrow_back_ios, color: AppColors.primary),
              ),
            ),
            bottom: TabBar(
              // Four sections do not fit a small phone in Lao: they scroll.
              isScrollable: tabs.length > 3,
              tabAlignment: tabs.length > 3 ? TabAlignment.start : null,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.subTitle,
              indicatorColor: AppColors.primary,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: [for (final tab in tabs) _tab(tab, l10n)],
            ),
          ),
          body: TabBarView(
            children: [for (final tab in tabs) _view(tab)],
          ),
        ),
      ),
    );
  }

  static Widget _tab(ApprovalsTab tab, AppLocalizations l10n) =>
      switch (tab) {
        // Badged with the pending count, and the watch that keeps the
        // leave approvals provider alive across tab switches.
        ApprovalsTab.leave => Tab(
          icon: const LeaveApprovalsBadgeIcon(),
          text: l10n.approvalsLeaveTab,
        ),
        ApprovalsTab.timeCorrection => Tab(
          icon: const Icon(Icons.more_time),
          text: l10n.approvalsTimeCorrectionTab,
        ),
        ApprovalsTab.offsite => Tab(
          icon: const Icon(Icons.wrong_location_outlined),
          text: l10n.approvalsOffsiteTab,
        ),
        ApprovalsTab.ot => Tab(
          icon: const Icon(Icons.work_history_outlined),
          text: l10n.apprSectionOt,
        ),
        ApprovalsTab.team => Tab(
          icon: const Icon(Icons.groups_outlined),
          text: l10n.apprSectionTeam,
        ),
      };

  static Widget _view(ApprovalsTab tab) => switch (tab) {
    ApprovalsTab.leave => const LeaveApprovalsTab(),
    ApprovalsTab.timeCorrection => const TimeCorrectionApprovalsTab(),
    ApprovalsTab.offsite => const OffsiteApprovalsTab(),
    ApprovalsTab.ot => const OtApprovalsTab(),
    ApprovalsTab.team => const TeamTab(),
  };
}
