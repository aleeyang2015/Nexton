import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/leave_duration_type.dart';
import '../../domain/entities/leave_request.dart';

part 'leave_request_form_state.freezed.dart';

/// The request-leave form's fields and submit status. One instance per form:
/// the "new request" tab uses the `null` family key, an edit page uses the
/// request's id.
///
/// Leave days are picked individually via [dates] (not a start/end range).
/// A half-day [durationType] forces exactly one date. The return-to-work date
/// defaults to the day after the latest selected date until the user
/// overrides it.
@freezed
class LeaveRequestFormState with _$LeaveRequestFormState {
  const LeaveRequestFormState._();

  const factory LeaveRequestFormState({
    /// Non-null once [LeaveRequestFormNotifier.seed] has run — i.e. edit mode.
    String? editingRequestId,
    String? leaveTypeId,
    @Default(<DateTime>[]) List<DateTime> dates,
    @Default(LeaveDurationType.fullDay) LeaveDurationType durationType,
    DateTime? returnToWorkOverride,
    @Default('') String reason,
    @Default(AsyncValue<LeaveRequest?>.data(null))
    AsyncValue<LeaveRequest?> submission,
  }) = _LeaveRequestFormState;

  bool get isEditing => editingRequestId != null;

  double get totalDays =>
      durationType.isHalfDay ? 0.5 : dates.length.toDouble();

  DateTime? get returnToWorkDate {
    if (returnToWorkOverride != null) return returnToWorkOverride;
    if (dates.isEmpty) return null;
    final sorted = [...dates]..sort();
    return sorted.last.add(const Duration(days: 1));
  }

  /// The form-intrinsic checks. The balance / attachment gate lives in the
  /// widget because it needs the selected [LeaveType] and its balance.
  bool get hasValidShape =>
      leaveTypeId != null &&
      dates.isNotEmpty &&
      (!durationType.isHalfDay || dates.length == 1) &&
      !submission.isLoading;
}
