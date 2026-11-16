import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/leave_duration_type.dart';
import '../../domain/entities/leave_request.dart';

part 'leave_request_form_state.freezed.dart';

/// The request-leave form's fields and submit status. One instance per form:
/// the "new request" tab uses the `null` family key, an edit page uses the
/// request's id.
///
/// Leave days are held in [dates] as individual days (not a start/end range),
/// chosen together in the multi-select calendar dialog and replaced wholesale
/// via [LeaveRequestFormNotifier.setDates].
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

    /// Edit mode only: the leave type the request had when it was opened. The
    /// form keeps offering it even after HR switched it off.
    String? originalLeaveTypeId,

    /// Edit mode only: how many days the request asked for when it was
    /// opened. The balance is checked on an edit only when the count grows
    /// past this, as the server does.
    double? originalTotalDays,

    /// Edit mode only: the year the request's days were charged to when it
    /// was opened (the year of its first leave day).
    int? originalBalanceYear,
    @Default(AsyncValue<LeaveRequest?>.data(null))
    AsyncValue<LeaveRequest?> submission,
  }) = _LeaveRequestFormState;

  bool get isEditing => editingRequestId != null;

  double get totalDays =>
      durationType.isHalfDay ? 0.5 : dates.length.toDouble();

  /// The earliest picked leave day (normalized to midnight), or null when
  /// none are picked. Its year is the one whose balance the request spends.
  DateTime? get firstLeaveDate {
    if (dates.isEmpty) return null;
    final first = ([...dates]..sort()).first;
    return DateTime(first.year, first.month, first.day);
  }

  /// True for an edit that still draws on the balance the request already
  /// drew on: the same leave type, in the same year. Only then do the days it
  /// already had count as covered.
  bool get editsSameBalance =>
      isEditing &&
      leaveTypeId == originalLeaveTypeId &&
      firstLeaveDate?.year == originalBalanceYear;

  /// The latest picked leave day (normalized to midnight), or null when none
  /// are picked.
  DateTime? get lastLeaveDate {
    if (dates.isEmpty) return null;
    final last = ([...dates]..sort()).last;
    return DateTime(last.year, last.month, last.day);
  }

  /// The earliest date the return-to-work picker may offer: the day after the
  /// last leave day. Null when no leave days are picked yet.
  DateTime? get earliestReturnToWorkDate =>
      lastLeaveDate?.add(const Duration(days: 1));

  DateTime? get returnToWorkDate {
    if (returnToWorkOverride != null) return returnToWorkOverride;
    return earliestReturnToWorkDate;
  }

  /// The return-to-work date must fall strictly after the last leave day — you
  /// can't already be back at work on a day you're still on leave. Vacuously
  /// true until leave days and a date exist.
  bool get hasValidReturnToWorkDate {
    final rtw = returnToWorkDate;
    final earliest = earliestReturnToWorkDate;
    if (rtw == null || earliest == null) return true;
    return !DateTime(rtw.year, rtw.month, rtw.day).isBefore(earliest);
  }

  /// The form-intrinsic checks. The balance / attachment gate lives in the
  /// widget because it needs the selected [LeaveType] and its balance.
  bool get hasValidShape =>
      leaveTypeId != null &&
      dates.isNotEmpty &&
      (!durationType.isHalfDay || dates.length == 1) &&
      hasValidReturnToWorkDate &&
      !submission.isLoading;
}
