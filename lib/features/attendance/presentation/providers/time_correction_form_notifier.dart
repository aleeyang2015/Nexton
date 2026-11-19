import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/domain/entities/employee_profile.dart';
import '../../../profile/domain/entities/shift_detail.dart';
import '../../../profile/presentation/providers/profile_notifier.dart';
import '../../attendance_providers.dart';
import '../../domain/correction_rules.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/date_range.dart';
import '../../domain/entities/time_correction_type.dart';
import 'time_correction_attachment_notifier.dart';
import 'time_correction_form_state.dart';

/// Fields, rules and submission of the time-correction request form
/// ("ລືມລົງເວລາ").
///
/// The parts offered are the picked day's own: those of its history sessions
/// (the month's records, read once per month), so a day worked on an earlier
/// shift is corrected against the part it was worked on. A day with no
/// session in any part gets the parts of the employee's profile
/// (`/core_hr/employees/me`'s `shift.shift_details[]`), which is also what
/// the form shows until the history has answered, and when it cannot be
/// read. The first part is picked by default, and picking a part pre-fills
/// the times with its schedule.
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
      // The profile landed after the day's parts: a part chosen from the
      // day's record gives way to the profile's full copy of it, and the
      // profile's first part to the day's own.
      _choosePart();
    });
    ref.onDispose(() => _disposed = true);

    final now = DateTime.now();
    final initial = TimeCorrectionFormState(
      date: DateTime(now.year, now.month, now.day),
    );
    // After this build: the answer changes the state.
    Future.microtask(() => _readDay(initial.date));
    final detail = _firstDetail(ref.read(profileNotifierProvider).valueOrNull);
    return detail == null ? initial : _withShiftDetail(initial, detail);
  }

  /// The day to correct. The parts offered become that day's own, and with
  /// a part chosen the times become that weekday's (the window under them
  /// moves to that day too).
  void setDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final next = state.copyWith(date: day, dayParts: _partsOn(day));
    final part = next.shiftDetail;
    state = part == null ? next : _withShiftDetail(next, part);
    _choosePart();
    _readDay(day);
  }

  /// The months of history read so far, by their first day. A month is read
  /// once for the form's life; one that failed is asked again on the next
  /// date picked in it.
  final Map<DateTime, List<AttendanceDay>> _months = {};
  final Set<DateTime> _reading = {};
  bool _disposed = false;

  /// Reads [day]'s month of history, unless it is known or on its way, then
  /// offers the parts of whichever day is picked by then.
  Future<void> _readDay(DateTime day) async {
    final month = DateTime(day.year, day.month);
    if (_disposed || _months.containsKey(month) || !_reading.add(month)) {
      return;
    }
    final result = await ref.read(getMonthlyRecordsUseCaseProvider)(
      DateRange.month(day),
    );
    _reading.remove(month);
    if (_disposed) return;

    // A failure is not an error on this form: the profile's parts stay.
    if (result.isFailure) return;
    final days = result.dataOrNull ?? const <AttendanceDay>[];
    _months[month] = days;
    state = state.copyWith(dayParts: _partsOn(state.date));
    _choosePart();
  }

  /// The parts of [day]'s sessions in the history read so far, each once, in
  /// the day's order. Empty when the day has none or its month is not read.
  List<ShiftDetail> _partsOn(DateTime day) {
    final days = _months[DateTime(day.year, day.month)] ?? const [];
    final parts = <ShiftDetail>[];
    for (final record in days) {
      final date = record.date;
      if (date == null ||
          date.year != day.year ||
          date.month != day.month ||
          date.day != day.day) {
        continue;
      }
      for (final session in record.sessions) {
        final part = session.part;
        if (part != null && !parts.any((p) => p.id == part.id)) {
          parts.add(part);
        }
      }
    }
    return parts;
  }

  /// Keeps the chosen part one of those on offer. A part still on offer is
  /// kept (as the profile's full copy, when the profile has it); otherwise
  /// the first one offered is chosen. A part a prefill still waits for is
  /// left to the profile's listener.
  void _choosePart() {
    if (_wantedPartId != null) return;
    final profile = ref.read(profileNotifierProvider).valueOrNull;
    final offered = offeredParts(
      profile?.shiftDetails ?? const <ShiftDetail>[],
    );
    if (offered.isEmpty) return;

    final chosenId = state.shiftDetail?.id;
    final part = offered.firstWhere(
      (p) => p.id == chosenId,
      orElse: () => offered.first,
    );
    if (state.shiftDetail != part) state = _withShiftDetail(state, part);
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

  /// The parts to offer: the picked day's own, when its history has any
  /// (each as the profile's full copy, when [profileParts] has it: the
  /// weekday rows and the minutes). Else the profile's [profileParts], after
  /// the history session's own part when the profile does not have it.
  List<ShiftDetail> offeredParts(List<ShiftDetail> profileParts) {
    final ofDay = state.dayParts;
    if (ofDay.isNotEmpty) {
      return [
        for (final part in ofDay)
          profileParts.firstWhere((p) => p.id == part.id, orElse: () => part),
      ];
    }
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
  /// through; then `state.submission` holds the new request's id, and on
  /// failure the reason is in its error.
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
      (id) {
        state = state.copyWith(submission: AsyncValue.data(id));
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
