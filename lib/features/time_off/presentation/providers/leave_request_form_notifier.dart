import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/leave_duration_type.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_request_draft.dart';
import '../../domain/entities/leave_type.dart';
import '../../time_off_providers.dart';
import 'company_days_off_notifier.dart';
import 'leave_attachment_notifier.dart';
import 'leave_balances_notifier.dart';
import 'leave_history_notifier.dart';
import 'leave_request_form_state.dart';
import 'leave_types_notifier.dart';

/// Owns one request-leave form's fields and its submission.
///
/// The family key is the id of the request being edited, or `null` for a new
/// request. Edit mode is entered by calling [seed] once with the request.
class LeaveRequestFormNotifier
    extends FamilyNotifier<LeaveRequestFormState, String?> {
  @override
  LeaveRequestFormState build(String? arg) {
    // The company's days off decide the day count and the return date, so the
    // state carries them. Null while loading or after a failed load: the
    // counts that need them are then unknown, never guessed.
    ref.listen(companyDaysOffNotifierProvider, (_, next) {
      state = state.copyWith(daysOff: next.valueOrNull);
    });

    return LeaveRequestFormState(
      daysOff: ref.read(companyDaysOffNotifierProvider).valueOrNull,
    );
  }

  /// Fills the form from an existing request (edit mode). Safe to call once,
  /// from the edit page's initState.
  void seed(LeaveRequest request) {
    if (state.isEditing) return;
    final days = [...request.requestDays]..sort();
    state = LeaveRequestFormState(
      editingRequestId: request.id,
      leaveTypeId: request.leaveType.id,
      // An edit shows the days the request was charged for, one by one. They
      // need not be next to each other, so they are not a range.
      mode: LeaveDaysMode.separateDays,
      daysOff: state.daysOff,
      dates: days,
      durationType: request.durationType,
      returnToWorkOverride: request.returnDate,
      reason: request.reason,
      originalLeaveTypeId: request.leaveType.id,
      originalTotalDays: request.totalDays,
      originalBalanceYear: (days.isEmpty ? request.startDate : days.first).year,
    );
  }

  /// Picks the leave type. A type that takes whole days only puts the form
  /// back on a full day in the same step, so a half day chosen under the
  /// previous type is never sent on it.
  ///
  /// The type's own `allow_half_day` is read from the loaded type list here,
  /// not handed in by the caller, so no caller can forget it. A type that is
  /// not in the list (it has not loaded) changes nothing but the selection.
  void setLeaveType(String leaveTypeId) {
    final types =
        ref.read(leaveTypesNotifierProvider).valueOrNull ?? const <LeaveType>[];
    final wholeDaysOnly = types.any(
      (type) => type.id == leaveTypeId && !type.allowHalfDay,
    );

    state = state.copyWith(
      leaveTypeId: leaveTypeId,
      durationType: wholeDaysOnly
          ? LeaveDurationType.fullDay
          : state.durationType,
    );
  }

  /// Switches between a date range and separate days, carrying over what
  /// was picked so the user does not start again:
  ///
  /// * to separate days — the range's days that are not days off (none when
  ///   the days off are not known: the form cannot say which they are);
  /// * to a range — from the first picked day to the last.
  ///
  /// A half day stays on separate days: it is one date.
  void setMode(LeaveDaysMode mode) {
    if (mode == state.mode) return;
    if (mode == LeaveDaysMode.range && state.durationType.isHalfDay) return;

    if (mode == LeaveDaysMode.separateDays) {
      state = state.copyWith(
        mode: mode,
        dates: state.chargedDays ?? const [],
        rangeStart: null,
        rangeEnd: null,
      );
      return;
    }

    final picked = [...state.dates]..sort();
    state = state.copyWith(
      mode: mode,
      rangeStart: picked.isEmpty ? null : picked.first,
      rangeEnd: picked.isEmpty ? null : picked.last,
      dates: const [],
    );
  }

  /// Sets the date range (from the calendar dialog), each end normalized to
  /// midnight and put in order, and puts the form in range mode.
  void setRange(DateTime start, DateTime end) {
    final a = DateTime(start.year, start.month, start.day);
    final b = DateTime(end.year, end.month, end.day);
    final ordered = a.isAfter(b) ? (b, a) : (a, b);

    state = state.copyWith(
      mode: LeaveDaysMode.range,
      rangeStart: ordered.$1,
      rangeEnd: ordered.$2,
      dates: const [],
    );
  }

  /// Replaces the picked leave days with [dates] (from the calendar dialog),
  /// each normalized to midnight, de-duplicated and sorted, and puts the form
  /// in separate-days mode. A half-day request keeps only the earliest date.
  void setDates(Iterable<DateTime> dates) {
    final normalized = <DateTime>{
      for (final d in dates) DateTime(d.year, d.month, d.day),
    }.toList()..sort();
    final updated = state.durationType.isHalfDay && normalized.length > 1
        ? [normalized.first]
        : normalized;
    state = state.copyWith(
      mode: LeaveDaysMode.separateDays,
      dates: updated,
      rangeStart: null,
      rangeEnd: null,
    );
  }

  void removeDate(DateTime date) {
    state = state.copyWith(dates: state.dates.where((d) => d != date).toList());
  }

  /// A half day is exactly one date, so choosing one moves the form to
  /// separate days and keeps the earliest day picked so far.
  void setDurationType(LeaveDurationType type) {
    if (!type.isHalfDay) {
      state = state.copyWith(durationType: type);
      return;
    }

    final first = state.firstLeaveDate;
    state = state.copyWith(
      durationType: type,
      mode: LeaveDaysMode.separateDays,
      dates: first == null ? const [] : [first],
      rangeStart: null,
      rangeEnd: null,
    );
  }

  void setReturnToWorkDate(DateTime date) =>
      state = state.copyWith(returnToWorkOverride: date);

  void setReason(String reason) => state = state.copyWith(reason: reason);

  /// Submits (or, in edit mode, updates) the form. Returns whether it
  /// succeeded. A range in which every day is a company day off is not sent:
  /// the server would refuse it. On success a new request resets the form;
  /// both paths invalidate the history and balance lists so the reserved days
  /// refresh.
  Future<bool> submit() async {
    final leaveTypeId = state.leaveTypeId;
    if (leaveTypeId == null ||
        !state.hasDays ||
        state.isAllDaysOff ||
        !state.hasValidReturnToWorkDate) {
      return false;
    }

    state = state.copyWith(submission: const AsyncValue.loading());
    final draft = LeaveRequestDraft(
      leaveTypeId: leaveTypeId,
      // A range goes as its two ends and the server leaves out the days off;
      // separate days go one by one.
      dates: state.isRange ? const [] : state.dates,
      startDate: state.isRange ? state.rangeStart : null,
      endDate: state.isRange ? state.rangeEnd : null,
      durationType: state.durationType,
      returnDate: state.returnToWorkDate,
      reason: state.reason,
      attachment: ref.read(leaveAttachmentNotifierProvider(arg)).valueOrNull,
    );

    final editingId = state.editingRequestId;
    final result = editingId == null
        ? await ref.read(submitLeaveRequestUseCaseProvider)(draft)
        : await ref.read(updateLeaveRequestUseCaseProvider)((
            id: editingId,
            draft: draft,
          ));

    return result.fold(
      (failure) {
        state = state.copyWith(
          submission: AsyncValue.error(failure, StackTrace.current),
        );
        return false;
      },
      (request) {
        if (editingId == null) {
          state = LeaveRequestFormState(daysOff: state.daysOff);
          ref.read(leaveAttachmentNotifierProvider(arg).notifier).clear();
        } else {
          state = state.copyWith(submission: AsyncValue.data(request));
        }
        ref.invalidate(leaveHistoryNotifierProvider);
        ref.invalidate(leaveBalancesNotifierProvider);
        return true;
      },
    );
  }
}

final leaveRequestFormNotifierProvider =
    NotifierProvider.family<
      LeaveRequestFormNotifier,
      LeaveRequestFormState,
      String?
    >(LeaveRequestFormNotifier.new);
