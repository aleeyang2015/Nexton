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
    // A rebuilt notifier starts clean.
    _disposed = false;
    _months.clear();
    _reading.clear();
    _sessionPart = null;
    _wantedPartId = null;
    _partPicked = false;
    _timesEdited = false;
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
        _partPicked = true;
        if (state.shiftDetail != match) _setPart(match);
        return;
      }
      // The profile has landed without it: there is nothing left to wait
      // for, and the parts on offer decide.
      if (profile != null) _wantedPartId = null;
      final detail = _firstDetail(profile);
      if (state.shiftDetail == null && detail != null) {
        state = _withShiftDetail(state, detail);
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
    // A part picked for another day is not a pick for this one.
    if (day != state.date) _partPicked = false;
    _timesEdited = false;
    final next = state.copyWith(date: day, dayParts: _partsOn(day));
    final part = next.shiftDetail;
    state = part == null ? next : _withShiftDetail(next, part);
    _choosePart();
    _readDay(day);
  }

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

  /// Keeps the chosen part right for the day picked.
  ///
  /// A part of the day's own sessions is kept, and so is one the user (or a
  /// history row, or a link) picked for this day, as long as it is on offer.
  /// Otherwise the first part offered is chosen: the day's own first, when
  /// it has any. A part a prefill still waits for (the profile has not
  /// loaded) is left to the profile's listener.
  void _choosePart() {
    if (_wantedPartId != null) return;
    final profile = ref.read(profileNotifierProvider).valueOrNull;
    final offered = offeredParts(
      profile?.shiftDetails ?? const <ShiftDetail>[],
    );
    if (offered.isEmpty) return;

    final chosenId = state.shiftDetail?.id;
    final ofDay = state.dayParts.any((p) => p.id == chosenId);
    final keep = ofDay || _partPicked || state.dayParts.isEmpty;
    final part = offered.firstWhere(
      (p) => keep && p.id == chosenId,
      orElse: () => offered.first,
    );
    if (state.shiftDetail != part) _setPart(part);
  }

  /// Chooses [part]. The times become its schedule, unless it is the part
  /// already chosen in a fuller or newer copy and the user has set the
  /// times: those are theirs.
  void _setPart(ShiftDetail part) {
    final sameAsChosen = part.id == state.shiftDetail?.id;
    if (sameAsChosen && _timesEdited) {
      state = state.copyWith(shiftDetail: part);
    } else {
      _timesEdited = false;
      state = _withShiftDetail(state, part);
    }
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
    // Not in the profile yet because it is still loading: its listener
    // lands on it. A loaded profile without it has nothing to wait for.
    final profileLoaded =
        ref.read(profileNotifierProvider).valueOrNull != null;
    _wantedPartId = fromProfile == null && !profileLoaded ? partId : null;
    final part = fromProfile ?? _sessionPart;
    if (part != null) {
      _partPicked = true;
      _timesEdited = false;
      state = _withShiftDetail(state, part);
    }
  }

  /// The parts to offer, each once: first the picked day's own, those of
  /// its history sessions (as the profile's full copy, when [profileParts]
  /// has it: the weekday rows and the minutes); then the history row's own
  /// part a prefill was given; then the rest of the profile's
  /// [profileParts], for a part of the day that was never scanned.
  List<ShiftDetail> offeredParts(List<ShiftDetail> profileParts) {
    final parts = <ShiftDetail>[];
    void add(ShiftDetail part) {
      if (!parts.any((p) => p.id == part.id)) parts.add(part);
    }

    for (final part in state.dayParts) {
      add(profileParts.firstWhere((p) => p.id == part.id, orElse: () => part));
    }
    final own = _sessionPart;
    if (own != null && !profileParts.any((p) => p.id == own.id)) add(own);
    profileParts.forEach(add);
    return parts;
  }

  /// The history session's part a prefill was given.
  ShiftDetail? _sessionPart;

  /// The part a prefill asked for, kept until the profile has loaded.
  String? _wantedPartId;

  /// The chosen part was picked for the day now on the form: by the user,
  /// a history row or a link. A day's history landing late does not undo it.
  bool _partPicked = false;

  /// The user set a time since the part's schedule was last filled in.
  bool _timesEdited = false;

  /// The months of history read so far, by their first day. A month is read
  /// once for the form's life; one that failed is asked again on the next
  /// date picked in it.
  final Map<DateTime, List<AttendanceDay>> _months = {};
  final Set<DateTime> _reading = {};
  bool _disposed = false;

  void setType(TimeCorrectionType type) => state = state.copyWith(type: type);

  /// The user's own pick: it outranks a part a prefill still waits for.
  void selectShiftDetail(ShiftDetail detail) {
    _wantedPartId = null;
    _partPicked = true;
    _timesEdited = false;
    state = _withShiftDetail(state, detail);
  }

  void setClockIn(TimeOfDay time) {
    _timesEdited = true;
    state = state.copyWith(clockIn: time);
  }

  void setClockOut(TimeOfDay time) {
    _timesEdited = true;
    state = state.copyWith(clockOut: time);
  }

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
