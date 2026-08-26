import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/leave_category.dart';
import '../../domain/entities/leave_request_draft.dart';
import '../../time_off_providers.dart';
import 'leave_history_notifier.dart';
import 'leave_request_form_state.dart';
import 'leave_summary_notifier.dart';

/// Owns the request-leave form's fields and submission.
class LeaveRequestFormNotifier extends Notifier<LeaveRequestFormState> {
  @override
  LeaveRequestFormState build() => const LeaveRequestFormState();

  void setCategory(LeaveCategory category) =>
      state = state.copyWith(category: category);

  /// Adds one leave day, ignoring a date already picked.
  void addDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (state.dates.contains(normalized)) return;
    final updated = [...state.dates, normalized]..sort();
    state = state.copyWith(dates: updated);
  }

  void removeDate(DateTime date) {
    state = state.copyWith(
      dates: state.dates.where((d) => d != date).toList(),
    );
  }

  void setReturnToWorkDate(DateTime date) =>
      state = state.copyWith(returnToWorkOverride: date);

  void setReason(String reason) => state = state.copyWith(reason: reason);

  /// Submits the form. Returns whether it succeeded; on success the form
  /// resets and the history/summary tabs are invalidated so they refetch.
  Future<bool> submit() async {
    final returnToWorkDate = state.returnToWorkDate;
    if (state.dates.isEmpty || returnToWorkDate == null) return false;

    state = state.copyWith(submission: const AsyncValue.loading());
    final draft = LeaveRequestDraft(
      category: state.category,
      dates: state.dates,
      returnToWorkDate: returnToWorkDate,
      reason: state.reason,
    );
    final result = await ref.read(submitLeaveRequestUseCaseProvider)(draft);

    return result.fold(
      (failure) {
        state = state.copyWith(
          submission: AsyncValue.error(failure, StackTrace.current),
        );
        return false;
      },
      (_) {
        state = const LeaveRequestFormState();
        ref.invalidate(leaveHistoryNotifierProvider);
        ref.invalidate(leaveSummaryNotifierProvider);
        return true;
      },
    );
  }
}

final leaveRequestFormNotifierProvider =
    NotifierProvider<LeaveRequestFormNotifier, LeaveRequestFormState>(
      LeaveRequestFormNotifier.new,
    );
