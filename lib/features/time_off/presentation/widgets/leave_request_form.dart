import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_balance.dart';
import '../../domain/entities/leave_duration_type.dart';
import '../../domain/entities/leave_type.dart';
import '../providers/leave_balances_notifier.dart';
import '../providers/leave_request_form_notifier.dart';
import '../providers/leave_request_form_state.dart';
import '../providers/leave_types_notifier.dart';
import 'leave_copy.dart';
import 'leave_filter_chip.dart';

/// The shared request-leave form: balance card, leave-type picker, day-part
/// selector, individually-picked dates, return-to-work date, an (unsupported)
/// attachment slot and a reason field. State and submission live in
/// [leaveRequestFormNotifierProvider]; this widget only renders it.
///
/// [requestId] is the family key — `null` for a new request, the request's id
/// on the edit page. [onSubmitted] fires after a successful submit/update.
class LeaveRequestForm extends ConsumerStatefulWidget {
  const LeaveRequestForm({super.key, this.requestId, this.onSubmitted});

  final String? requestId;
  final VoidCallback? onSubmitted;

  @override
  ConsumerState<LeaveRequestForm> createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends ConsumerState<LeaveRequestForm> {
  final _reasonController = TextEditingController();
  bool _reasonSeeded = false;

  LeaveRequestFormNotifier get _notifier =>
      ref.read(leaveRequestFormNotifierProvider(widget.requestId).notifier);

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  LeaveType? _selectedType(List<LeaveType> types, String? id) {
    for (final type in types) {
      if (type.id == id) return type;
    }
    return null;
  }

  /// The reason the submit button is blocked, or null when it can go through.
  String? _blockMessage(
    AppLocalizations l10n,
    LeaveRequestFormState state,
    LeaveType? type,
    LeaveBalance? balance,
  ) {
    if (type == null) return null;
    if (type.requiresAttachment) return l10n.leaveRequiresAttachmentBlocked;

    final max = type.maxDaysPerRequest;
    if (max != null && state.totalDays > max) return l10n.leaveMaxDaysHint(max);

    if (balance != null &&
        !type.allowNegativeBalance &&
        state.totalDays > balance.remainingDays) {
      return l10n.leaveInsufficientBalanceHint;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final key = widget.requestId;
    final state = ref.watch(leaveRequestFormNotifierProvider(key));
    final typesAsync = ref.watch(leaveTypesNotifierProvider);
    final balances = ref.watch(leaveBalancesNotifierProvider).valueOrNull;

    final types = typesAsync.valueOrNull ?? const <LeaveType>[];
    final selectedType = _selectedType(types, state.leaveTypeId);
    final balance = leaveBalanceFor(balances, state.leaveTypeId);

    // Seed the reason field once, and default the leave type to the first one.
    if (!_reasonSeeded && state.reason.isNotEmpty) {
      _reasonController.text = state.reason;
      _reasonSeeded = true;
    }
    if (state.leaveTypeId == null && types.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            ref.read(leaveRequestFormNotifierProvider(key)).leaveTypeId ==
                null) {
          _notifier.setLeaveType(types.first.id);
        }
      });
    }

    final blockMessage = _blockMessage(l10n, state, selectedType, balance);
    // Never enable submit before the chosen type's rules are known.
    final typeResolved = types.isNotEmpty && selectedType != null;
    final canSubmit =
        state.hasValidShape && blockMessage == null && typeResolved;

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
        children: [
          _BalanceCard(balance: balance, hasType: selectedType != null),
          heightBx(h: 16),
          _SectionCard(
            title: l10n.leaveRequestCategoryLabel,
            child: _LeaveTypePicker(
              types: types,
              loading: typesAsync.isLoading,
              failed: typesAsync.hasError,
              selectedId: state.leaveTypeId,
              onSelect: _notifier.setLeaveType,
            ),
          ),
          if (selectedType?.allowHalfDay ?? false) ...[
            heightBx(h: 16),
            _SectionCard(
              title: l10n.leaveDurationLabel,
              child: _DurationSelector(
                selected: state.durationType,
                onSelect: _notifier.setDurationType,
              ),
            ),
          ],
          heightBx(h: 16),
          _SectionCard(
            title: l10n.leaveSelectDatesLabel,
            titleTrailing: _AddDateButton(
              dates: state.dates,
              // A half-day request is a single date.
              enabled:
                  !(state.durationType.isHalfDay && state.dates.isNotEmpty),
              onPick: _notifier.addDate,
            ),
            child: _DatesList(
              dates: state.dates,
              totalDays: state.totalDays,
              onRemove: _notifier.removeDate,
            ),
          ),
          heightBx(h: 16),
          _SectionCard(
            title: l10n.leaveReturnToWorkLabel,
            child: _ReturnToWorkRow(
              date: state.returnToWorkDate,
              onPick: _notifier.setReturnToWorkDate,
            ),
          ),
          heightBx(h: 16),
          _SectionCard(
            title: l10n.leaveAttachFileLabel,
            titleBadge: (selectedType?.requiresAttachment ?? false)
                ? l10n.leaveRequiredBadge
                : l10n.leaveOptionalBadge,
            titleTrailing: _AttachFileButton(
              onTap: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.comingSoon))),
            ),
          ),
          heightBx(h: 16),
          _SectionCard(
            title: l10n.leaveRequestReasonLabel,
            child: TextField(
              controller: _reasonController,
              maxLines: 4,
              onChanged: _notifier.setReason,
              decoration: inputDecoration(l10n.leaveRequestReasonHint),
            ),
          ),
          if (blockMessage != null && state.dates.isNotEmpty) ...[
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
    final messenger = ScaffoldMessenger.of(context);
    final wasEditing = ref
        .read(leaveRequestFormNotifierProvider(widget.requestId))
        .isEditing;

    final ok = await _notifier.submit();
    if (!mounted) return;

    if (ok) {
      _reasonController.clear();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            wasEditing
                ? l10n.leaveRequestUpdated
                : l10n.leaveRequestSubmitSuccess,
          ),
        ),
      );
      widget.onSubmitted?.call();
      return;
    }

    final error = ref
        .read(leaveRequestFormNotifierProvider(widget.requestId))
        .submission
        .error;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error is Failure ? error.localize(l10n) : l10n.genericError,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _BalanceCard extends StatelessWidget {
  final LeaveBalance? balance;
  final bool hasType;

  const _BalanceCard({required this.balance, required this.hasType});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final year = balance?.year ?? DateTime.now().year;
    final remaining = balance == null
        ? '-'
        : LeaveCopy.daysLabel(l10n, balance!.remainingDays);
    final used = balance?.usedDays.round() ?? 0;

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
                    remaining,
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
      padding: const EdgeInsets.all(14),
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
                      child: customText(
                        title,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
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
            ],
          ),
          if (child != null) ...[heightBx(h: 12), child!],
        ],
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

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
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

class _DurationSelector extends StatelessWidget {
  final LeaveDurationType selected;
  final ValueChanged<LeaveDurationType> onSelect;

  const _DurationSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in LeaveDurationType.values)
          LeaveFilterChip(
            label: LeaveCopy.durationLabel(l10n, type),
            selected: type == selected,
            onTap: () => onSelect(type),
          ),
      ],
    );
  }
}

class _AddDateButton extends StatelessWidget {
  final List<DateTime> dates;
  final bool enabled;
  final ValueChanged<DateTime> onPick;

  const _AddDateButton({
    required this.dates,
    required this.enabled,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: enabled
          ? () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: dates.isEmpty
                    ? now
                    : dates.last.add(const Duration(days: 1)),
                firstDate: now.subtract(const Duration(days: 365)),
                lastDate: now.add(const Duration(days: 365)),
              );
              if (picked != null) onPick(picked);
            }
          : null,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.gray300,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
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
  final ValueChanged<DateTime> onPick;

  const _ReturnToWorkRow({required this.date, required this.onPick});

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
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: now.subtract(const Duration(days: 365)),
              lastDate: now.add(const Duration(days: 365)),
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
  final VoidCallback onTap;

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
