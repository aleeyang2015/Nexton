import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/leave_duration_type.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_request_draft.dart';
import '../../time_off_providers.dart';
import 'leave_balances_notifier.dart';
import 'leave_history_notifier.dart';
import 'leave_request_form_state.dart';

/// Owns one request-leave form's fields and its submission.
///
/// The family key is the id of the request being edited, or `null` for a new
/// request. Edit mode is entered by calling [seed] once with the request.
class LeaveRequestFormNotifier
    extends FamilyNotifier<LeaveRequestFormState, String?> {
  @override
  LeaveRequestFormState build(String? arg) => const LeaveRequestFormState();

  /// Fills the form from an existing request (edit mode). Safe to call once,
  /// from the edit page's initState.
  void seed(LeaveRequest request) {
    if (state.isEditing) return;
    state = LeaveRequestFormState(
      editingRequestId: request.id,
      leaveTypeId: request.leaveType.id,
      dates: [...request.requestDays]..sort(),
      durationType: request.durationType,
      returnToWorkOverride: request.returnDate,
      reason: request.reason,
    );
  }

  void setLeaveType(String leaveTypeId) =>
      state = state.copyWith(leaveTypeId: leaveTypeId);

  /// Adds one leave day, ignoring a date already picked. A half-day request
  /// keeps only the earliest date.
  void addDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (state.dates.contains(normalized)) return;
    var updated = [...state.dates, normalized]..sort();
    if (state.durationType.isHalfDay && updated.length > 1) {
      updated = [updated.first];
    }
    state = state.copyWith(dates: updated);
  }

  void removeDate(DateTime date) {
    state = state.copyWith(dates: state.dates.where((d) => d != date).toList());
  }

  void setDurationType(LeaveDurationType type) {
    var dates = state.dates;
    if (type.isHalfDay && dates.length > 1) {
      dates = [
        ([...dates]..sort()).first,
      ];
    }
    state = state.copyWith(durationType: type, dates: dates);
  }

  void setReturnToWorkDate(DateTime date) =>
      state = state.copyWith(returnToWorkOverride: date);

  void setReason(String reason) => state = state.copyWith(reason: reason);

  /// Submits (or, in edit mode, updates) the form. Returns whether it
  /// succeeded. On success a new request resets the form; both paths
  /// invalidate the history and balance lists so the reserved days refresh.
  Future<bool> submit() async {
    final leaveTypeId = state.leaveTypeId;
    if (leaveTypeId == null || state.dates.isEmpty) return false;

    state = state.copyWith(submission: const AsyncValue.loading());
    final draft = LeaveRequestDraft(
      leaveTypeId: leaveTypeId,
      dates: state.dates,
      durationType: state.durationType,
      returnDate: state.returnToWorkDate,
      reason: state.reason,
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
          state = const LeaveRequestFormState();
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
