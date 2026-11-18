import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/network/paged_list.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/image_viewer.dart';
import '../../../../core/widgets/paged_list_end.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../attendance/domain/attendance_failure_x.dart';
import '../../../attendance/domain/entities/time_correction_detail.dart';
import '../../../attendance/domain/entities/time_correction_status.dart';
import '../../../attendance/presentation/widgets/requests_list_message.dart';
import '../../../attendance/presentation/widgets/time_correction_approval_card.dart';
import '../../../attendance/presentation/widgets/time_correction_copy.dart';
import '../../../time_off/domain/entities/leave_request.dart';
import '../../../time_off/domain/entities/leave_status.dart';
import '../../../time_off/presentation/widgets/leave_filter_chip.dart';
import '../providers/team_corrections_notifier.dart';
import '../providers/team_leave_notifier.dart';
import '../providers/team_list_notifier.dart';
import 'team_leave_row.dart';

/// "ທີມຂອງຂ້ອຍ" (#50), for department heads: their team's leave and
/// "forgot to scan" requests, every status, read-only. Two lists behind a
/// switch, each loaded the first time it shows. Kept alive across tab
/// switches.
class TeamTab extends ConsumerStatefulWidget {
  const TeamTab({super.key});

  @override
  ConsumerState<TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends ConsumerState<TeamTab>
    with AutomaticKeepAliveClientMixin {
  bool _corrections = false;

  /// The lists shown so far: each stays (its chip, its pages) while the
  /// tab lives, so switching back does not load it again.
  bool _leaveShown = false;
  bool _correctionsShown = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    if (_corrections) {
      _correctionsShown = true;
    } else {
      _leaveShown = true;
    }
    if (_leaveShown) ref.watch(teamLeaveNotifierProvider.select((_) => 0));
    if (_correctionsShown) {
      ref.watch(teamCorrectionsNotifierProvider.select((_) => 0));
    }

    return Container(
      color: AppColors.homeBackground,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 4),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.apprTeamLeave)),
                ButtonSegment(
                  value: true,
                  label: Text(l10n.apprTeamCorrections),
                ),
              ],
              selected: {_corrections},
              showSelectedIcon: false,
              onSelectionChanged: (picked) =>
                  setState(() => _corrections = picked.first),
            ),
          ),
          Expanded(
            // Only the list on show is built, so each loads when first shown.
            child: _corrections
                ? const _TeamCorrectionsList()
                : const _TeamLeaveList(),
          ),
        ],
      ),
    );
  }
}

class _TeamLeaveList extends StatelessWidget {
  const _TeamLeaveList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _TeamList<LeaveRequest, LeaveStatus>(
      provider: teamLeaveNotifierProvider,
      loadFailed: l10n.leaveApprovalsLoadFailed,
      chips: [
        (null, l10n.leaveFilterAll),
        (LeaveStatus.pending, l10n.leaveStatusPending),
        (LeaveStatus.approved, l10n.leaveStatusApproved),
        (LeaveStatus.rejected, l10n.leaveStatusRejected),
        (LeaveStatus.cancelled, l10n.leaveStatusCancelled),
      ],
      row: (context, request) => TeamLeaveRow(
        request: request,
        onTap: () =>
            context.push(AppRoutes.teamLeave(request.id), extra: request),
      ),
    );
  }
}

class _TeamCorrectionsList extends StatelessWidget {
  const _TeamCorrectionsList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _TeamList<TimeCorrectionDetail, TimeCorrectionStatus>(
      provider: teamCorrectionsNotifierProvider,
      loadFailed: l10n.timeCorrectionApprovalsLoadFailed,
      chips: [
        (null, l10n.leaveFilterAll),
        for (final status in TimeCorrectionStatus.values)
          (status, TimeCorrectionCopy.statusLabel(l10n, status)),
      ],
      row: (context, request) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            context.push(AppRoutes.teamCorrection(request.id), extra: request),
        // The approver's card, with no buttons: read-only.
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TimeCorrectionApprovalCard(
            request: request,
            onViewImage: (url) => showImageViewer(
              context,
              url,
              errorText: l10n.leaveFileOpenFailed,
            ),
          ),
        ),
      ),
    );
  }
}

/// One "My team" list: its status chips, its rows (already filtered), load
/// more and pull to refresh. "None" shows only once the list has ended.
class _TeamList<T, S> extends ConsumerWidget {
  const _TeamList({
    required this.provider,
    required this.chips,
    required this.row,
    required this.loadFailed,
  });

  /// "Couldn't load …", in this list's words.
  final String loadFailed;

  final AutoDisposeNotifierProvider<TeamListNotifier<T, S>, TeamListState<T, S>>
  provider;
  final List<(S?, String)> chips;
  final Widget Function(BuildContext context, T row) row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final value = state.rows;
    final list = value.valueOrNull;
    final rows = state.visible;

    return RefreshIndicator(
      onRefresh: () async {
        final failure = await notifier.refresh();
        // The rows shown stay; say why they were not renewed.
        if (failure != null) AppToast.error(failure.localize(l10n));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(15, 8, 15, 40),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (status, label) in chips)
                LeaveFilterChip(
                  label: label,
                  selected: state.status == status,
                  onTap: () => notifier.select(status),
                ),
            ],
          ),
          heightBx(h: 12),
          ..._body(context, l10n, value, list, rows, notifier),
          if (list != null && !value.isLoading)
            PagedListEnd(
              list: list,
              onLoadMore: notifier.loadMore,
              onRetry: notifier.retryLoadMore,
            ),
        ],
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<PagedList<T>> value,
    PagedList<T>? list,
    List<T> rows,
    TeamListNotifier<T, S> notifier,
  ) {
    if (value.isLoading && list == null) return const [_Loading()];

    if (value.hasError && list == null) {
      // No staff record: #11's text, and nothing to retry.
      final error = value.error;
      final notLinked = error is Failure && error.isEmployeeNotLinked;
      return [
        RequestsListMessage(
          icon: Icons.error_outline,
          text: notLinked ? error.localize(l10n) : loadFailed,
          onRetry: notLinked ? null : notifier.refresh,
        ),
      ];
    }

    if (rows.isEmpty) {
      // The pages so far held only rows this head does not see: more are on
      // their way (the footer's spinner), or the next one failed (its Retry
      // is below). Never "none" while the list has not ended.
      if (list != null && list.hasMore) return const [];
      return [
        RequestsListMessage(
          icon: Icons.groups_outlined,
          text: l10n.apprTeamEmpty,
        ),
      ];
    }

    return [for (final r in rows) row(context, r)];
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      2,
      (_) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: ShimmerBox(width: double.infinity, height: 110),
      ),
    ),
  );
}
