import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/network/paged_list.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/load_more_footer.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../time_off/presentation/widgets/leave_filter_chip.dart';
import '../../domain/entities/ot_request.dart';
import '../providers/ot_list_notifier.dart';
import '../../../profile/presentation/providers/profile_notifier.dart';
import '../widgets/ot_clock_hints_card.dart';
import '../widgets/ot_copy.dart';
import '../widgets/ot_month_picker_dialog.dart';
import '../widgets/ot_request_row.dart';

/// "ໂອທີ": the employee's OT requests, newest asked first, with status chips
/// and a month filter. Pull to refresh; the next page loads near the end.
/// Everything comes from [otListNotifierProvider].
class OtListPage extends ConsumerStatefulWidget {
  const OtListPage({super.key});

  @override
  ConsumerState<OtListPage> createState() => _OtListPageState();
}

class _OtListPageState extends ConsumerState<OtListPage> {
  /// How close to the end of the list, in pixels, the next page is asked
  /// for.
  static const double _loadMoreWithin = 300;

  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_loadMoreIfNearEnd);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// True while a request's page is open, or opening: a second tap, however
  /// fast, opens nothing.
  bool _opening = false;

  /// Opens [request]'s page. The page keeps this list's row up to date
  /// itself (changed in place, or taken out when gone), so going back asks
  /// for nothing and the pages already loaded stay.
  Future<void> _open(OtRequest request) async {
    if (_opening) return;
    _opening = true;
    try {
      await context.push<void>(
        AppRoutes.otRequest(request.id),
        extra: request,
      );
    } finally {
      _opening = false;
    }
  }

  void _loadMoreIfNearEnd() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter > _loadMoreWithin) return;
    ref.read(otListNotifierProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(otListNotifierProvider);
    final notifier = ref.read(otListNotifierProvider.notifier);
    final list = state.requests.valueOrNull;

    // A page that does not fill the screen leaves nothing to scroll, so no
    // scroll would ever ask for the next one. Check once it is laid out.
    ref.listen(otListNotifierProvider.select((s) => s.requests), (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadMoreIfNearEnd();
      });
    });

    // Ask shows once the profile says this employee may ask (`can_ask_ot`).
    // Not while it loads (no flash), not when it failed; a server that does
    // not send the flag (null) shows it, and its refusal explains.
    final canAskOt = ref.watch(
      profileNotifierProvider.select(
        (p) => p.hasValue && p.valueOrNull?.canAskOt != false,
      ),
    );

    return Container(
      color: AppColors.homeBackground,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          floatingActionButton: canAskOt
              ? FloatingActionButton.extended(
                  onPressed: () => context.push(AppRoutes.otAsk),
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: customText(
                    l10n.otAsk,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heightBx(h: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: popBack(),
                    ),
                    widthBx(w: 4),
                    Expanded(
                      child: customText(
                        l10n.otMenu,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              heightBx(h: 8),
              _StatusChips(selected: state.status, onSelect: notifier.setStatus),
              heightBx(h: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: _MonthButton(month: state.month, onPick: notifier.setMonth),
              ),
              heightBx(h: 8),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // A profile that failed hid Ask: ask for it again too.
                    if (ref.read(profileNotifierProvider).hasError) {
                      ref.invalidate(profileNotifierProvider);
                    }
                    final loaded = await notifier.refresh();
                    if (!loaded && context.mounted) {
                      AppToast.error(l10n.otListLoadFailed);
                    }
                  },
                  child: ListView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(15, 8, 15, 96),
                    children: [
                      const OtClockHintsCard(),
                      heightBx(h: 12),
                      _Body(
                        requests: state.requests,
                        onRetry: notifier.retry,
                        onOpen: _open,
                      ),
                      if (list != null && !state.requests.isLoading)
                        LoadMoreFooter(
                          loadingMore: list.loadingMore,
                          failed: list.loadMoreError != null,
                          onRetry: notifier.retryLoadMore,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ທັງໝົດ · ກຳລັງດຳເນີນການ · ອະນຸມັດແລ້ວ · ບໍ່ອະນຸມັດ · ຍົກເລີກແລ້ວ.
class _StatusChips extends StatelessWidget {
  final OtStatus? selected;
  final void Function(OtStatus?) onSelect;

  const _StatusChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chips = <(OtStatus?, String)>[
      (null, l10n.leaveFilterAll),
      (OtStatus.pending, l10n.leaveStatusPending),
      (OtStatus.approved, l10n.leaveStatusApproved),
      (OtStatus.rejected, l10n.leaveStatusRejected),
      (OtStatus.cancelled, l10n.leaveStatusCancelled),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: chips.length,
        separatorBuilder: (_, _) => widthBx(w: 8),
        itemBuilder: (_, i) => LeaveFilterChip(
          label: chips[i].$2,
          selected: chips[i].$1 == selected,
          onTap: () => onSelect(chips[i].$1),
        ),
      ),
    );
  }
}

/// "ທຸກເດືອນ" or the month chosen; opens the month picker.
class _MonthButton extends StatelessWidget {
  final DateTime? month;
  final void Function(DateTime?) onPick;

  const _MonthButton({required this.month, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return OutlinedButton.icon(
      onPressed: () async {
        final choice = await showOtMonthPicker(context, current: month);
        if (choice != null) onPick(choice.month);
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(
        Icons.calendar_month_outlined,
        size: 18,
        color: AppColors.primary,
      ),
      label: customText(
        OtCopy.monthLabel(l10n, month),
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// The rows, or why there are none.
class _Body extends StatelessWidget {
  final AsyncValue<PagedList<OtRequest>> requests;
  final VoidCallback onRetry;
  final void Function(OtRequest) onOpen;

  const _Body({
    required this.requests,
    required this.onRetry,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final list = requests.valueOrNull;

    if (list == null && requests.isLoading) {
      return Column(
        children: [
          for (var i = 0; i < 3; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerBox(
                width: double.infinity,
                height: 84,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
        ],
      );
    }

    if (requests.hasError && !requests.isLoading) {
      final shown = OtCopy.listError(l10n, requests.error);
      return _Message(
        text: shown.message,
        retryLabel: shown.canRetry ? l10n.retry : null,
        onRetry: onRetry,
      );
    }

    if (list == null || list.items.isEmpty) {
      return _Message(text: l10n.otListEmpty);
    }

    return Column(
      children: [
        for (final r in list.items)
          OtRequestRow(request: r, onTap: () => onOpen(r)),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final String? retryLabel;
  final VoidCallback? onRetry;

  const _Message({required this.text, this.retryLabel, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final retryLabel = this.retryLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          customText(
            text,
            color: AppColors.subTitle,
            alight: TextAlign.center,
            maxLine: 4,
          ),
          if (retryLabel != null) ...[
            heightBx(h: 12),
            TextButton(
              onPressed: onRetry,
              child: customText(
                retryLabel,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
