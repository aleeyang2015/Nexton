import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/domain/entities/employee_profile.dart';
import '../../../profile/domain/entities/shift_detail.dart';
import '../../../profile/presentation/providers/profile_notifier.dart';
import '../../attendance_providers.dart';
import '../../domain/entities/time_correction_type.dart';
import 'time_correction_attachment_notifier.dart';
import 'time_correction_form_state.dart';

/// Fields, rules and submission of the time-correction request form
/// ("ລືມລົງເວລາ").
///
/// The shift comes from the employee's profile (`/core_hr/employees/me`'s
/// `shift.shift_details[]`) rather than a fetch of its own — the attendance
/// card already reads it from there. The first segment is picked by default,
/// and picking a segment pre-fills the times with its schedule.
class TimeCorrectionFormNotifier
    extends AutoDisposeNotifier<TimeCorrectionFormState> {
  @override
  TimeCorrectionFormState build() {
    // The profile may still be loading when the form opens; take the first
    // segment once it lands, unless the user has picked one already.
    ref.listen(profileNotifierProvider, (_, next) {
      final detail = _firstDetail(next.valueOrNull);
      if (state.shiftDetail == null && detail != null) {
        selectShiftDetail(detail);
      }
    });

    final now = DateTime.now();
    final initial = TimeCorrectionFormState(
      date: DateTime(now.year, now.month, now.day),
    );
    final detail = _firstDetail(ref.read(profileNotifierProvider).valueOrNull);
    return detail == null ? initial : _withShiftDetail(initial, detail);
  }

  void setDate(DateTime date) =>
      state = state.copyWith(date: DateTime(date.year, date.month, date.day));

  void setType(TimeCorrectionType type) => state = state.copyWith(type: type);

  void selectShiftDetail(ShiftDetail detail) =>
      state = _withShiftDetail(state, detail);

  void setClockIn(TimeOfDay time) => state = state.copyWith(clockIn: time);

  void setClockOut(TimeOfDay time) => state = state.copyWith(clockOut: time);

  void setReason(String reason) => state = state.copyWith(reason: reason);

  /// Validates the form and files the request, with the already-uploaded
  /// evidence file (if any) as `attachment_url`. Returns whether it went
  /// through; on failure the reason is in `state.submission`'s error.
  Future<bool> submit() async {
    if (state.isSubmitting) return false;

    final request = state.toRequest();
    final validation = request.validate();
    if (validation.isFailure) {
      state = state.copyWith(
        showErrors: true,
        submission: AsyncValue.error(
          validation.failureOrNull!,
          StackTrace.current,
        ),
      );
      return false;
    }

    state = state.copyWith(submission: const AsyncValue.loading());

    final attachment = ref
        .read(timeCorrectionAttachmentNotifierProvider)
        .valueOrNull
        ?.uploaded;

    final result = await ref.read(submitTimeCorrectionUseCaseProvider)(
      request.withAttachment(attachment),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          submission: AsyncValue.error(failure, StackTrace.current),
        );
        return false;
      },
      (_) {
        state = state.copyWith(submission: const AsyncValue.data(null));
        return true;
      },
    );
  }

  static ShiftDetail? _firstDetail(EmployeeProfile? profile) {
    final details = profile?.shiftDetails ?? const <ShiftDetail>[];
    return details.isEmpty ? null : details.first;
  }

  /// [form] with [detail] selected and its schedule as the default times.
  static TimeCorrectionFormState _withShiftDetail(
    TimeCorrectionFormState form,
    ShiftDetail detail,
  ) {
    return form.copyWith(
      shiftDetail: detail,
      clockIn: _timeOf(detail.startTime) ?? form.clockIn,
      clockOut: _timeOf(detail.endTime) ?? form.clockOut,
    );
  }

  /// The backend's `HH:mm[:ss]` schedule string as a [TimeOfDay].
  static TimeOfDay? _timeOf(String? raw) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw ?? '');
    if (match == null) return null;
    return TimeOfDay(
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    );
  }
}

final timeCorrectionFormNotifierProvider =
    NotifierProvider.autoDispose<
      TimeCorrectionFormNotifier,
      TimeCorrectionFormState
    >(TimeCorrectionFormNotifier.new);
