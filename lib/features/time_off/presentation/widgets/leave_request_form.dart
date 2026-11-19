import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/clock_provider.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/datasources/leave_error_code.dart';
import '../../domain/entities/leave_balance.dart';
import '../../domain/entities/leave_type.dart';
import '../providers/company_days_off_notifier.dart';
import '../providers/leave_balances_notifier.dart';
import '../providers/leave_form_rules.dart';
import '../providers/leave_request_form_notifier.dart';
import '../providers/leave_request_form_state.dart';
import '../providers/leave_types_notifier.dart';
import 'leave_copy.dart';
import 'leave_dates_calendar_dialog.dart';
import 'leave_filter_chip.dart';
import '../../../../core/upload/domain/capture_policy.dart';
import '../../../../core/upload/presentation/file_source_sheet.dart';
import '../../domain/entities/leave_attachment.dart';

/// The shared request-leave form: balance card, leave-type picker, day-part
/// selector, a multi-select date calendar, return-to-work date, the files
/// (camera, gallery or a file → `POST /uploads`, kept in the form's state and
/// sent as the body's `attachments`) and a reason field. Form
/// fields and submission live in [leaveRequestFormNotifierProvider]; this
/// widget only renders them.
///
/// [requestId] is the family key — `null` for a new request, the request's id
/// on the edit page. [onSubmitted] fires after a successful submit/update.
class LeaveRequestForm extends ConsumerStatefulWidget {
  const LeaveRequestForm({
    super.key,
    this.requestId,
    this.onSubmitted,
    this.header,
    this.submitBlocked = false,
  });

  final String? requestId;
  final VoidCallback? onSubmitted;

  /// Shown above the form's first card, and scrolls with it.
  final Widget? header;

  /// Keeps the submit button off whatever the form holds: the host knows a
  /// reason the server would refuse (a request already waiting).
  final bool submitBlocked;

  @override
  ConsumerState<LeaveRequestForm> createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends ConsumerState<LeaveRequestForm> {
  final _reasonController = TextEditingController();
  bool _reasonSeeded = false;

  LeaveRequestFormNotifier get _notifier =>
      ref.read(leaveRequestFormNotifierProvider(widget.requestId).notifier);

  @override
  void initState() {
    super.initState();
    // The draft outlives this screen, and so would the days off it was last
    // told. Start from what is known now: nothing while they load, so a new
    // login is never counted by the last one's company.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifier.setDaysOff(
        ref.read(companyDaysOffNotifierProvider).valueOrNull,
      );
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  /// Opens the full-screen leave-type chooser and applies whatever it returns.
  /// A back-out returns null and leaves the current selection alone.
  Future<void> _openLeaveTypePicker() async {
    final key = widget.requestId;
    final current = ref.read(leaveRequestFormNotifierProvider(key));
    final picked = await context.push<String>(
      AppRoutes.timeOffLeaveTypePicker,
      extra: (
        selectedTypeId: current.leaveTypeId,
        allowClear: false,
        // The same exception the chips make for a request being edited.
        keepTypeId: current.originalLeaveTypeId,
      ),
    );
    if (picked != null && picked.isNotEmpty) _notifier.setLeaveType(picked);
  }

  /// Opens the calendar in the form's current mode, seeded with the current
  /// pick, and applies whatever it returns: a range's two ends, or the
  /// separate days. A back-out leaves the selection alone.
  Future<void> _openDatesCalendar() async {
    final current = ref.read(leaveRequestFormNotifierProvider(widget.requestId));
    final picked = await LeaveDatesCalendarDialog.show(
      context,
      mode: current.mode,
      initialDates: current.dates,
      initialRangeStart: current.rangeStart,
      initialRangeEnd: current.rangeEnd,
      halfDay: current.durationType.isHalfDay,
      daysOff: current.daysOff,
    );
    if (picked == null) return;

    final start = picked.rangeStart;
    final end = picked.rangeEnd;
    if (current.isRange) {
      if (start != null && end != null) _notifier.setRange(start, end);
    } else {
      _notifier.setDates(picked.dates);
    }
  }

  LeaveType? _selectedType(List<LeaveType> types, String? id) {
    for (final type in types) {
      if (type.id == id) return type;
    }
    return null;
  }

  /// The words for why the submit button is blocked, or null when it is not.
  /// Whether it is blocked is [LeaveFormRules.block]'s call, not this
  /// widget's.
  String? _blockMessage(
    AppLocalizations l10n,
    LeaveFormBlock? block,
    LeaveType? type,
  ) => switch (block) {
    null => null,
    LeaveFormBlock.returnDate => l10n.leaveReturnDateHint,
    LeaveFormBlock.attachmentRequired => l10n.leaveRequiresAttachmentBlocked,
    LeaveFormBlock.maxDays => l10n.leaveMaxDaysHint(
      LeaveCopy.dayCount(type?.maxDaysPerRequest ?? 0),
    ),
    LeaveFormBlock.insufficientBalance => l10n.leaveInsufficientBalanceHint,
    LeaveFormBlock.allDaysOff => l10n.leaveAllDaysOff,
  };

  /// "ແນບໄຟລ໌": the camera, the gallery, or an image or PDF file
  /// (decision 23), then the upload. Several files may be attached.
  Future<void> _attach() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await FileSourceSheet.pick(
      context,
      ref,
      CapturePolicy.document,
    );
    switch (picked) {
      case Captured(:final file):
        await _notifier.addFile(file);
      case CaptureFailed():
        AppToast.error(l10n.uploadInvalidFile);
      case CaptureDenied():
        AppToast.error(l10n.uploadPermissionDenied);
      case CaptureCancelled():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final key = widget.requestId;
    final state = ref.watch(leaveRequestFormNotifierProvider(key));
    final typesAsync = ref.watch(leaveTypesNotifierProvider);
    // Shown as a warning when it fails. The list itself is handed to the
    // form's state as it arrives, changes or is lost.
    final daysOffFailed = ref.watch(
      companyDaysOffNotifierProvider.select((value) => value.hasError),
    );
    ref.listen(companyDaysOffNotifierProvider, (_, next) {
      _notifier.setDaysOff(next.valueOrNull);
    });
    // Each leave day is charged to its own year, so the form reads the
    // balance of every year the request touches: two for a leave across the
    // new year, one otherwise. And the year the server named as short when
    // it refused what was sent, if the form could not tell it (#87).
    final balanceYears = LeaveFormRules.yearsToRead(
      state,
      ref.watch(clockProvider)(),
    );
    final balancesByYear = {
      for (final year in balanceYears)
        year: ref.watch(leaveBalancesNotifierProvider(year)),
    };
    // Each year is loaded the first time a day in it is picked. Until it
    // answers, what is left is not known, and the form waits rather than send
    // a request the server is about to refuse.
    final balanceLoading = balancesByYear.values.any(
      (balances) => balances.isLoading && !balances.hasValue,
    );

    final allTypes = typesAsync.valueOrNull ?? const <LeaveType>[];
    // Only the types HR has switched on, plus, when editing, the request's
    // own type even if it has been switched off since.
    final types = LeaveFormRules.offered(
      allTypes,
      keepId: state.originalLeaveTypeId,
    );
    final selectedType = _selectedType(types, state.leaveTypeId);
    final remainingByYear = {
      for (final entry in balancesByYear.entries)
        entry.key: LeaveFormRules.remainingDays(
          entry.value.valueOrNull,
          state.leaveTypeId,
        ),
    };
    final cardYear = LeaveFormRules.cardYear(
      state: state,
      type: selectedType,
      years: balanceYears,
      remainingByYear: remainingByYear,
    );
    final balance = leaveBalanceFor(
      balancesByYear[cardYear]?.valueOrNull,
      state.leaveTypeId,
    );
    final remaining = remainingByYear[cardYear];

    // Seed the reason field once, and default the leave type to the first one.
    if (!_reasonSeeded && state.reason.isNotEmpty) {
      _reasonController.text = state.reason;
      _reasonSeeded = true;
    }
    // A new request starts on the first type on offer, and goes back to it
    // when the type it was on is no longer offered (HR switched it off while
    // the form was open). An edit keeps its own type, which stays on offer.
    // A type the server refused is not replaced either: the user was told to
    // pick another, and picks it.
    final needsDefault =
        types.isNotEmpty &&
        !state.typeRefused &&
        (state.leaveTypeId == null ||
            (!state.isEditing && selectedType == null));
    if (needsDefault) {
      final unusable = state.leaveTypeId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            ref.read(leaveRequestFormNotifierProvider(key)).leaveTypeId ==
                unusable) {
          _notifier.setLeaveType(types.first.id);
        }
      });
    }

    final blockMessage = _blockMessage(
      l10n,
      LeaveFormRules.block(
        state: state,
        type: selectedType,
        remainingByYear: remainingByYear,
      ),
      selectedType,
    );
    // Never enable submit before the chosen type's rules are known.
    final typeResolved =
        types.isNotEmpty && selectedType != null && !state.typeRefused;
    final canSubmit =
        !widget.submitBlocked &&
        state.hasValidShape &&
        blockMessage == null &&
        typeResolved &&
        !balanceLoading;

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
        children: [
          if (widget.header != null) ...[widget.header!, heightBx(h: 12)],
          _BalanceCard(
            balance: balance,
            remaining: selectedType == null ? null : remaining,
            year: cardYear,
          ),
          heightBx(h: 16),
          _SectionCard(
            title: l10n.leaveRequestCategoryLabel,
            titleTrailing: _LeaveTypeExpandButton(onTap: _openLeaveTypePicker),
            child: _LeaveTypePicker(
              types: types,
              loading: typesAsync.isLoading,
              failed: typesAsync.hasError,
              // A refused type is shown as not picked: it has to be picked
              // again (or another one) before anything is sent.
              selectedId: state.typeRefused ? null : state.leaveTypeId,
              onSelect: _notifier.setLeaveType,
            ),
          ),
          // The day-part card ("ຊ່ວງເວລາ": full day / first half / second half)
          // is hidden for now — every request goes in as a full day.
          // `LeaveRequestFormState.durationType` already defaults to
          // `LeaveDurationType.fullDay` and nothing here changes it, so the
          // half-day branches downstream stay dormant. To bring the picker
          // back, un-comment this block and `_DurationSelector` /
          // `_DurationRadioTile` below.
          // if (selectedType?.allowHalfDay ?? false) ...[
          //   heightBx(h: 16),
          //   _SectionCard(
          //     title: l10n.leaveDurationLabel,
          //     child: _DurationSelector(
          //       selected: state.durationType,
          //       onSelect: _notifier.setDurationType,
          //     ),
          //   ),
          // ],
          heightBx(h: 16),
          _SectionCard(
            title: l10n.leaveSelectDatesLabel,
            titleTrailing: _PickDatesButton(onTap: _openDatesCalendar),
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A half day is one date, so there is no range to offer.
                  if (!state.durationType.isHalfDay) ...[
                    _DaysModeSwitch(
                      mode: state.mode,
                      onSelect: _notifier.setMode,
                    ),
                    heightBx(h: 10),
                  ],
                  if (daysOffFailed) ...[
                    _DaysOffLoadFailed(
                      onRetry: () => ref
                          .read(companyDaysOffNotifierProvider.notifier)
                          .refresh(),
                    ),
                    heightBx(h: 10),
                  ],
                  if (state.isRange)
                    _RangeSummary(
                      start: state.rangeStart,
                      end: state.rangeEnd,
                      totalDays: state.totalDays,
                    )
                  else
                    _DatesList(
                      dates: state.dates,
                      totalDays: state.totalDays ?? 0,
                      onRemove: _notifier.removeDate,
                    ),
                ],
              ),
            ),
          ),
          heightBx(h: 16),
          _SectionCard(
            title: l10n.leaveReturnToWorkLabel,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: _ReturnToWorkRow(
                date: state.returnToWorkDate,
                earliest: state.earliestReturnToWorkDate,
                onPick: _notifier.setReturnToWorkDate,
              ),
            ),
          ),
          heightBx(h: 16),
          _SectionCard(
            title: l10n.leaveAttachFileLabel,
            titleBadge: (selectedType?.requiresAttachment ?? false)
                ? l10n.leaveRequiredBadge
                : l10n.leaveOptionalBadge,
            // Off while the request is being sent: a file picked then would
            // not go with it.
            titleTrailing: _AttachFileButton(
              onTap: state.submission.isLoading ? null : _attach,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: _FileList(
                files: state.files,
                uploading: state.uploadingFiles,
                failure: state.fileFailure,
                onRemove: state.submission.isLoading
                    ? null
                    : _notifier.removeFile,
              ),
            ),
          ),
          heightBx(h: 16),
          _SectionCard(
            title: l10n.leaveRequestReasonLabel,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: TextField(
                controller: _reasonController,
                maxLines: 4,
                onChanged: _notifier.setReason,
                style: AppTextStyles.inputStyle,
                decoration: inputDecoration(l10n.leaveRequestReasonHint),
              ),
            ),
          ),
          if (blockMessage != null && state.hasDays) ...[
            heightBx(h: 14),
            _BlockNotice(message: blockMessage),
          ],
          heightBx(h: 24),
          button(
            _submit,
            state.isEditing ? l10n.leaveEditAction : l10n.leaveRequestSubmit,
            enabled: canSubmit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final wasEditing = ref
        .read(leaveRequestFormNotifierProvider(widget.requestId))
        .isEditing;

    final ok = await _notifier.submit();
    if (!mounted) return;

    if (ok) {
      _reasonController.clear();
      AppToast.success(
        wasEditing ? l10n.leaveRequestUpdated : l10n.leaveRequestSubmitSuccess,
      );
      widget.onSubmitted?.call();
      return;
    }

    final error = ref
        .read(leaveRequestFormNotifierProvider(widget.requestId))
        .submission
        .error;
    AppToast.error(
      error is Failure ? error.localize(l10n) : l10n.genericError,
    );

    // The request being edited is out of date; the notifier has reloaded
    // the lists. Saving again would fail the same way, so close the page.
    if (wasEditing &&
        error is Failure &&
        LeaveErrorCode.isStaleForOwner(error)) {
      widget.onSubmitted?.call();
    }
  }
}

// ---------------------------------------------------------------------------

/// What is left of the selected leave type in [year]: a year the request is
/// charged to (`LeaveFormRules.cardYear` picks which, when there are two).
class _BalanceCard extends StatelessWidget {
  /// The type's row for [year], or null when it has none (or nothing has
  /// loaded yet).
  final LeaveBalance? balance;

  /// The days left to show: null while unknown, which shows a dash; 0 for a
  /// type with no row that year.
  final double? remaining;
  final int year;

  const _BalanceCard({
    required this.balance,
    required this.remaining,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = remaining;
    final remainingLabel = days == null ? '-' : LeaveCopy.daysLabel(l10n, days);
    final used = LeaveCopy.dayCount(balance?.usedDays ?? 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          widthBx(w: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  l10n.leaveBalanceRemainingLabel,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: customText(
                    remainingLabel,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          widthBx(w: 8),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                customText(
                  l10n.leaveBalanceUsedLabel(used),
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  alight: TextAlign.right,
                ),
                heightBx(h: 4),
                customText(
                  l10n.leaveYearLabel(year),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  alight: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? titleBadge;
  final Widget? titleTrailing;
  final Widget? child;

  const _SectionCard({
    required this.title,
    this.titleBadge,
    this.titleTrailing,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: customText(
                          title,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (titleBadge != null) ...[
                      widthBx(w: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: customText(
                          titleBadge!,
                          fontSize: 10,
                          color: AppColors.subTitle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (titleTrailing != null) ...[widthBx(w: 8), titleTrailing!],
              widthBx(),
            ],
          ),
          if (child != null) ...[heightBx(h: 12), child!],
        ],
      ),
    );
  }
}

/// The arrow-down affordance on the "Leave type" card. Opens the full-screen
/// searchable chooser; the horizontal chip row stays as the quick picker.
class _LeaveTypeExpandButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LeaveTypeExpandButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primaryTint,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.keyboard_arrow_down,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }
}

class _LeaveTypePicker extends StatelessWidget {
  final List<LeaveType> types;
  final bool loading;
  final bool failed;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _LeaveTypePicker({
    required this.types,
    required this.loading,
    required this.failed,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (failed) {
      return customText(
        l10n.leaveTypeLoadFailed,
        color: AppColors.subTitle,
        fontSize: 13,
      );
    }
    if (loading && types.isEmpty) {
      return customText('…', color: AppColors.subTitle);
    }
    // Loaded, and nothing to offer: every type is switched off.
    if (types.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: customText(
          l10n.leaveTypeSearchEmpty,
          color: AppColors.subTitle,
          fontSize: 13,
        ),
      );
    }

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        padding: EdgeInsets.only(left: 12, right: 12),
        separatorBuilder: (_, _) => widthBx(w: 8),
        itemBuilder: (context, i) {
          final type = types[i];
          return LeaveFilterChip(
            label: LeaveCopy.leaveTypeLabel(l10n, type),
            selected: type.id == selectedId,
            onTap: () => onSelect(type.id),
          );
        },
      ),
    );
  }
}

// Day-part picker — temporarily unused (see the commented block in `build`).
// Requests are full-day only for now; restore both classes and that block
// together.
/*
class _DurationSelector extends StatelessWidget {
  final LeaveDurationType selected;
  final ValueChanged<LeaveDurationType> onSelect;

  const _DurationSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          for (final type in LeaveDurationType.values)
            _DurationRadioTile(
              label: LeaveCopy.durationLabel(l10n, type),
              selected: type == selected,
              onTap: () => onSelect(type),
            ),
        ],
      ),
    );
  }
}

/// One option of the day-part radio group: a circular indicator and its label,
/// the whole item tappable. Sized to its content so the group can be laid out
/// horizontally.
class _DurationRadioTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DurationRadioTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? AppColors.primary : AppColors.gray400,
            ),
            widthBx(w: 6),
            customText(
              label,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
*/

/// Opens the multi-select date calendar for the "Select leave dates" card.
class _PickDatesButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PickDatesButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.edit_calendar, color: Colors.white, size: 18),
      ),
    );
  }
}

/// The two ways to choose the days: a date range, or separate days.
class _DaysModeSwitch extends StatelessWidget {
  final LeaveDaysMode mode;
  final ValueChanged<LeaveDaysMode> onSelect;

  const _DaysModeSwitch({required this.mode, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        LeaveFilterChip(
          label: l10n.leaveModeRange,
          selected: mode == LeaveDaysMode.range,
          onTap: () => onSelect(LeaveDaysMode.range),
        ),
        LeaveFilterChip(
          label: l10n.leaveModeSeparateDays,
          selected: mode == LeaveDaysMode.separateDays,
          onTap: () => onSelect(LeaveDaysMode.separateDays),
        ),
      ],
    );
  }
}

/// The company's days off could not be loaded. A range can still be sent
/// (the server leaves the days off out), and separate days can still be
/// picked, so this warns and offers a Retry; it does not block.
class _DaysOffLoadFailed extends StatelessWidget {
  final VoidCallback onRetry;

  const _DaysOffLoadFailed({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
        widthBx(w: 6),
        Expanded(
          child: customText(
            l10n.leaveDaysOffLoadFailed,
            fontSize: 12.5,
            color: AppColors.subTitle,
            maxLine: 2,
          ),
        ),
        widthBx(w: 8),
        InkWell(
          onTap: onRetry,
          child: customText(
            l10n.retry,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

/// A date range as the form shows it: "from – to · N days", and a line saying
/// the company's days off are not counted. While those days are not known
/// the count is left to the server, and the line says so.
class _RangeSummary extends StatelessWidget {
  final DateTime? start;
  final DateTime? end;

  /// The days the range would be charged for; null when not known.
  final double? totalDays;

  const _RangeSummary({
    required this.start,
    required this.end,
    required this.totalDays,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final from = start;
    final to = end;

    if (from == null || to == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: customText(
          l10n.leaveNoDatesSelected,
          color: AppColors.subTitle,
          fontSize: 13,
        ),
      );
    }

    final days = totalDays;
    final range =
        '${LeaveCopy.shortDate(l10n, from)} – ${LeaveCopy.shortDate(l10n, to)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            widthBx(w: 10),
            Expanded(
              child: customText(
                days == null
                    ? range
                    : '$range · ${LeaveCopy.daysLabel(l10n, days)}',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                maxLine: 2,
              ),
            ),
          ],
        ),
        heightBx(h: 6),
        customText(
          days == null
              ? l10n.leaveRangeCountByServer
              : l10n.leaveRangeSkipsDaysOff,
          fontSize: 12.5,
          color: AppColors.subTitle,
          maxLine: 2,
        ),
      ],
    );
  }
}

class _DatesList extends StatelessWidget {
  final List<DateTime> dates;
  final double totalDays;
  final ValueChanged<DateTime> onRemove;

  const _DatesList({
    required this.dates,
    required this.totalDays,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (dates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: customText(
          l10n.leaveNoDatesSelected,
          color: AppColors.subTitle,
          fontSize: 13,
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < dates.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                widthBx(w: 10),
                Expanded(
                  child: customText(
                    _format(dates[i]),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                InkWell(
                  onTap: () => onRemove(dates[i]),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
        const Divider(height: 1, color: AppColors.border),
        heightBx(h: 10),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              customText(
                l10n.leaveDatesTotalPrefix,
                fontSize: 13,
                color: AppColors.subTitle,
              ),
              widthBx(w: 4),
              customText(
                LeaveCopy.daysLabel(l10n, totalDays),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _ReturnToWorkRow extends StatelessWidget {
  final DateTime? date;

  /// The earliest date the picker may offer — the day after the last leave
  /// day. Null until leave days are picked, in which case the picker falls
  /// back to a year ago.
  final DateTime? earliest;
  final ValueChanged<DateTime> onPick;

  const _ReturnToWorkRow({
    required this.date,
    required this.earliest,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = date;

    return Row(
      children: [
        Expanded(
          child: customText(
            value == null ? '—' : _format(value),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final firstDate =
                earliest ?? now.subtract(const Duration(days: 365));
            final lastDate = now.add(const Duration(days: 365));
            final picked = await showDatePicker(
              context: context,
              initialDate: value != null && !value.isBefore(firstDate)
                  ? value
                  : firstDate,
              firstDate: firstDate,
              // Guard the picker's own assert: the last leave day can sit
              // beyond the usual one-year horizon.
              lastDate: lastDate.isAfter(firstDate)
                  ? lastDate
                  : firstDate.add(const Duration(days: 365)),
            );
            if (picked != null) onPick(picked);
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: AppColors.primary,
          ),
          label: customText(
            l10n.leaveSelectButtonLabel,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _AttachFileButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _AttachFileButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.attach_file, size: 15, color: AppColors.primary),
      label: customText(
        l10n.leaveChooseFileButton,
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }
}

/// The request's files: each with a thumbnail (a photo) or an icon, its
/// name, and a remove ×; a spinner per upload on its way; the reason the
/// last upload failed, under the list.
class _FileList extends StatelessWidget {
  final List<LeaveAttachment> files;
  final int uploading;
  final Failure? failure;
  final void Function(int index)? onRemove;

  const _FileList({
    required this.files,
    required this.uploading,
    required this.failure,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final failure = this.failure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (files.isEmpty && uploading == 0)
          _hint(null, l10n.leaveAttachNoFiles),
        for (var i = 0; i < files.length; i++)
          _FileRow(
            file: files[i],
            removeLabel: l10n.leaveFileRemove,
            onRemove: onRemove == null ? null : () => onRemove!(i),
          ),
        for (var i = 0; i < uploading; i++)
          _hint(const _UploadSpinner(), l10n.leaveAttachUploading),
        if (failure != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: customText(
              failure.localize(l10n),
              color: AppColors.danger,
              fontSize: 12.5,
              maxLine: 3,
            ),
          ),
      ],
    );
  }

  Widget _hint(Widget? leading, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (leading != null) ...[leading, widthBx(w: 8)],
          customText(text, color: AppColors.subTitle, fontSize: 13),
        ],
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  final LeaveAttachment file;
  final String removeLabel;
  final VoidCallback? onRemove;

  const _FileRow({
    required this.file,
    required this.removeLabel,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final url = file.url;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: file.isImage && url != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      // Decoded at the thumbnail's size, not the photo's.
                      cacheWidth:
                          (36 * MediaQuery.devicePixelRatioOf(context)).round(),
                      errorBuilder: (_, _, _) => _icon(Icons.image_outlined),
                    ),
                  )
                : _icon(
                    file.isPdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.insert_drive_file_outlined,
                  ),
          ),
          widthBx(w: 10),
          Expanded(
            child: customText(
              file.displayName,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              maxLine: 2,
            ),
          ),
          IconButton(
            tooltip: removeLabel,
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 20, color: AppColors.danger),
          ),
        ],
      ),
    );
  }

  static Widget _icon(IconData icon) =>
      Center(child: Icon(icon, size: 22, color: AppColors.primary));
}

class _UploadSpinner extends StatelessWidget {
  const _UploadSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 14,
      height: 14,
      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
    );
  }
}

class _BlockNotice extends StatelessWidget {
  final String message;

  const _BlockNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
          widthBx(w: 8),
          Expanded(
            child: customText(
              message,
              fontSize: 12.5,
              color: AppColors.textPrimary,
              maxLine: 4,
            ),
          ),
        ],
      ),
    );
  }
}
