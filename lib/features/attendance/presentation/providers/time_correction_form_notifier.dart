import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/domain/entities/employee_profile.dart';
import '../../../profile/domain/entities/shift_detail.dart';
import '../../../profile/presentation/providers/profile_notifier.dart';
import '../../attendance_providers.dart';
import '../../domain/correction_rules.dart';
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
      final profile = next.valueOrNull;
      // The part asked for (a history row's) lands once the profile has it:
      // the profile's own, full (weekday rows, minutes), also in place of a
      // session's bare copy already chosen. Then it is forgotten, so a later
      // refresh cannot undo the user's own pick.
      final wanted = _wantedPartId;
      final match = wanted == null ? null : _partWithId(profile, wanted);
      if (match != null) {
        _wantedPartId = null;
        if (state.shiftDetail != match) state = _withShiftDetail(state, match);
        return;
      }
      final detail = _firstDetail(profile);
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

  /// The day to correct. With a part chosen, the times become that
  /// weekday's (the window under them moves to that day too).
  void setDate(DateTime date) {
    final next = state.copyWith(
      date: DateTime(date.year, date.month, date.day),
    );
    final part = next.shiftDetail;
    state = part == null ? next : _withShiftDetail(next, part);
  }

  /// Fills the form for a day and part (#44): from a history row, or a link
  /// (`?date=&part=`). A date outside the look-back is not taken. The part is
  /// the profile's with [partId], else [sessionPart] (the history row's own,
  /// when the profile no longer has it); its times are that weekday's.
  void prefill({DateTime? date, String? partId, ShiftDetail? sessionPart}) {
    if (date != null && CorrectionRules.inLookBack(date, DateTime.now())) {
      setDate(date);
    }
    if (partId == null) return;
    if (sessionPart?.id == partId) _sessionPart = sessionPart;
    final fromProfile = _partWithId(
      ref.read(profileNotifierProvider).valueOrNull,
      partId,
    );
    // Not in the profile yet (still loading): its listener lands on it.
    if (fromProfile == null) _wantedPartId = partId;
    final part = fromProfile ?? _sessionPart;
    if (part != null) state = _withShiftDetail(state, part);
  }

  /// The parts to offer: the history session's own part when the profile
  /// does not have it, then the profile's [profileParts].
  List<ShiftDetail> offeredParts(List<ShiftDetail> profileParts) {
    final own = _sessionPart;
    return [
      if (own != null && !profileParts.any((p) => p.id == own.id)) own,
      ...profileParts,
    ];
  }

  /// The history session's part a prefill was given.
  ShiftDetail? _sessionPart;

  /// The part a prefill asked for, kept until the profile has loaded.
  String? _wantedPartId;

  void setType(TimeCorrectionType type) => state = state.copyWith(type: type);

  /// The user's own pick: it outranks a part a prefill still waits for.
  void selectShiftDetail(ShiftDetail detail) {
    _wantedPartId = null;
    state = _withShiftDetail(state, detail);
  }

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

  static ShiftDetail? _partWithId(EmployeeProfile? profile, String id) {
    for (final part in profile?.shiftDetails ?? const <ShiftDetail>[]) {
      if (part.id == id) return part;
    }
    return null;
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
    // That weekday's times (#44), when HR set a row for it.
    final times = detail.timesOn(form.date);
    return form.copyWith(
      shiftDetail: detail,
      clockIn: _timeOf(times.start) ?? form.clockIn,
      clockOut: _timeOf(times.end) ?? form.clockOut,
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
