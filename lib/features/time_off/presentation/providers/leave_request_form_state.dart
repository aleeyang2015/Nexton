import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/failure.dart';

import '../../domain/entities/company_days_off.dart';
import '../../domain/entities/leave_attachment.dart';
import '../../domain/entities/leave_duration_type.dart';
import '../../domain/entities/leave_request.dart';

part 'leave_request_form_state.freezed.dart';

/// How the form's leave days are chosen.
enum LeaveDaysMode {
  /// From one day to another. The request is sent as a range and the server
  /// leaves out the company's days off.
  range,

  /// Days picked one by one, next to each other or not (the 1st and the 15th
  /// in one request). The calendar does not offer the company's days off.
  separateDays,
}

/// The request-leave form's fields and submit status. One instance per form:
/// the "new request" tab uses the `null` family key, an edit page uses the
/// request's id.
///
/// The leave days are chosen in one of two ways ([mode]): a date range
/// ([rangeStart]–[rangeEnd]) or separate days ([dates]). A new request opens
/// on a range; an edit opens on the request's own days. A half-day
/// [durationType] is always exactly one date in separate-days mode.
///
/// Every count here is a preview. The server counts the days of a request,
/// and its answer is the truth.
@freezed
class LeaveRequestFormState with _$LeaveRequestFormState {
  const LeaveRequestFormState._();

  const factory LeaveRequestFormState({
    /// Non-null once [LeaveRequestFormNotifier.seed] has run — i.e. edit mode.
    String? editingRequestId,
    String? leaveTypeId,
    @Default(LeaveDaysMode.range) LeaveDaysMode mode,

    /// Separate-days mode: the days picked, sorted.
    @Default(<DateTime>[]) List<DateTime> dates,

    /// Range mode: the first and the last day asked for, both included.
    DateTime? rangeStart,
    DateTime? rangeEnd,
    @Default(LeaveDurationType.fullDay) LeaveDurationType durationType,
    DateTime? returnToWorkOverride,
    @Default('') String reason,

    /// The company's days off, or null while they are not known (still
    /// loading, or the load failed). Handed in by the form on screen
    /// (`setDaysOff`) so the counts below need nothing passed to them.
    CompanyDaysOff? daysOff,

    /// The server refused the chosen leave type as switched off or gone.
    /// Until the user picks a type again nothing is sent, and the form does
    /// not pick one for them.
    @Default(false) bool typeRefused,

    /// The year the server said is short of days when it refused what this
    /// form last sent (#87): the card shows that year's balance. Forgotten
    /// as soon as the days or the type change, since the refusal was about
    /// the request as it was sent.
    int? balanceRefusedYear,

    /// Edit mode only: the leave type the request had when it was opened. The
    /// form keeps offering it even after HR switched it off.
    String? originalLeaveTypeId,

    /// Edit mode only: how many days the request had in each year when it
    /// was opened. Each leave day is charged to its own year, and an edit is
    /// checked against a year's balance only when it asks for more days in
    /// that year than this, as the server does.
    @Default(<int, double>{}) Map<int, double> originalDaysByYear,

    /// Edit mode only: the days the request had when it was opened. A day
    /// among them that is a company day off now (HR changed the calendar
    /// since) does not stop the edit; only a day off added does (#128).
    @Default(<DateTime>[]) List<DateTime> originalDates,

    /// The request's files: on an edit, those it had (as the server sent
    /// them), then any uploaded here.
    @Default(<LeaveAttachment>[]) List<LeaveAttachment> files,

    /// True once a file was added or removed here: only then does an edit
    /// send `attachments` (the whole list), which replaces the request's.
    @Default(false) bool filesChanged,

    /// How many files are being uploaded now. Nothing is sent meanwhile.
    @Default(0) int uploadingFiles,

    /// Why the last upload failed; cleared by the next pick.
    Failure? fileFailure,
    @Default(AsyncValue<LeaveRequest?>.data(null))
    AsyncValue<LeaveRequest?> submission,
  }) = _LeaveRequestFormState;

  bool get isEditing => editingRequestId != null;

  bool get isRange => mode == LeaveDaysMode.range;

  /// True once the form has days to send: a whole range, or at least one
  /// separate day.
  bool get hasDays =>
      isRange ? rangeStart != null && rangeEnd != null : dates.isNotEmpty;

  /// The days the request would be charged for, as far as the form can tell,
  /// sorted — or null when it cannot tell: a range whose days off are not
  /// known. Empty when nothing is picked, or a range is all days off.
  List<DateTime>? get chargedDays {
    if (!isRange) return [...dates]..sort();

    final start = rangeStart;
    final end = rangeEnd;
    if (start == null || end == null) return const [];
    return daysOff?.workingDaysBetween(start, end);
  }

  /// How many days the request asks for: half a day, the separate days
  /// picked, or the days of the range that are not days off. Null when that
  /// last count is not known, and the server will do the counting.
  double? get totalDays {
    if (durationType.isHalfDay) return hasDays ? 0.5 : 0;
    return chargedDays?.length.toDouble();
  }

  /// True for a range in which every day is a company day off: there is
  /// nothing to ask for, and the server would refuse it.
  bool get isAllDaysOff => isRange && hasDays && totalDays == 0;

  /// How many days the request asks for in each year: every leave day is
  /// charged to the balance of its own year. Null when the count is not
  /// known (a range whose days off are not known); empty when nothing is
  /// picked.
  Map<int, double>? get daysByYear {
    final charged = chargedDays;
    if (charged == null) return null;
    if (durationType.isHalfDay) {
      return charged.isEmpty ? const {} : {charged.first.year: 0.5};
    }
    final byYear = <int, double>{};
    for (final day in charged) {
      byYear[day.year] = (byYear[day.year] ?? 0) + 1;
    }
    return byYear;
  }

  /// The first leave day (normalized to midnight), or null when none is
  /// picked. For a range it is the first day that is not a day off, or the
  /// range's own first day while the days off are not known.
  DateTime? get firstLeaveDate => _dateOnly(_edge(first: true));

  /// The days in [year] an edit already has, and so does not need the
  /// balance for: what the request had there when it was opened, as long as
  /// it is still on the same leave type. Moved to another type it is
  /// spending a balance it never had days in, so nothing is covered; a new
  /// request has none either.
  double coveredDays(int year) =>
      isEditing && leaveTypeId == originalLeaveTypeId
      ? originalDaysByYear[year] ?? 0
      : 0;

  /// The last leave day (normalized to midnight), or null when none is
  /// picked.
  DateTime? get lastLeaveDate => _dateOnly(_edge(first: false));

  /// True when [year] is one the days asked for reach into: from the year
  /// of the first day to the year of the last. False for null, or with no
  /// day picked.
  bool touchesYear(int? year) {
    final first = firstLeaveDate?.year;
    final last = lastLeaveDate?.year;
    if (year == null || first == null || last == null) return false;
    return year >= first && year <= last;
  }

  DateTime? _edge({required bool first}) {
    final charged = chargedDays;
    if (charged != null && charged.isNotEmpty) {
      return first ? charged.first : charged.last;
    }
    // A range with unknown, or only, days off: its own ends.
    if (isRange) return first ? rangeStart : rangeEnd;
    return null;
  }

  static DateTime? _dateOnly(DateTime? date) =>
      date == null ? null : DateTime(date.year, date.month, date.day);

  /// The earliest date the return-to-work picker may offer: the day after the
  /// last leave day, and for a range the day after its last day even when
  /// that one is a day off, so the return never falls inside the range that
  /// is sent. Null when no leave days are picked yet.
  DateTime? get earliestReturnToWorkDate {
    final last = isRange ? _dateOnly(rangeEnd) ?? lastLeaveDate : lastLeaveDate;
    return last == null ? null : DateTime(last.year, last.month, last.day + 1);
  }

  /// When the employee is back: the date they chose, else the first day after
  /// the leave that is not a company day off. After a Saturday-only leave at
  /// a company closed on Sundays, that is Monday. While the days off are not
  /// known it is simply the next day.
  DateTime? get returnToWorkDate {
    if (returnToWorkOverride != null) return returnToWorkOverride;

    final last = lastLeaveDate;
    if (last == null) return null;
    return daysOff?.firstWorkingDayAfter(last) ?? earliestReturnToWorkDate;
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

  /// The form-intrinsic checks. What depends on the selected leave type and
  /// its balance is `LeaveFormRules.block`'s.
  bool get hasValidShape =>
      leaveTypeId != null &&
      hasDays &&
      (!durationType.isHalfDay || (!isRange && dates.length == 1)) &&
      hasValidReturnToWorkDate &&
      uploadingFiles == 0 &&
      !submission.isLoading;
}
