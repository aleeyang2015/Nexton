import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/leave_error_code.dart';
import '../../data/datasources/leave_rule_code.dart';
import '../../../../core/upload/domain/local_file.dart';
import '../../../../core/upload/domain/upload_rules.dart';
import '../../../../core/upload/domain/uploaded_attachment.dart';
import '../../../../core/upload/upload_providers.dart';
import '../../domain/entities/company_days_off.dart';
import '../../domain/entities/leave_attachment.dart';
import '../../domain/entities/leave_duration_type.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_request_draft.dart';
import '../../domain/entities/leave_type.dart';
import '../../time_off_providers.dart';
import 'leave_balances_notifier.dart';
import 'leave_history_notifier.dart';
import 'leave_pending_request_notifier.dart';
import 'leave_request_form_state.dart';
import 'leave_types_notifier.dart';

/// Owns one request-leave form's fields and its submission.
///
/// The family key is the id of the request being edited, or `null` for a new
/// request. Edit mode is entered by calling [seed] once with the request.
///
/// Not `autoDispose`: a draft is kept while its user looks at another screen.
/// It is that user's only. The form is built again, empty, when the
/// signed-in user changes or signs out (#83), so the next login on a shared
/// phone never finds the last one's days, reason or files.
class LeaveRequestFormNotifier
    extends FamilyNotifier<LeaveRequestFormState, String?> {
  @override
  LeaveRequestFormState build(String? arg) {
    ref.watch(leaveDraftOwnerProvider);
    // The same notifier is built again for the next user: nothing of the
    // last form stays.
    _stale = false;
    _seededFrom = null;
    _form++;
    _builds++;
    return const LeaveRequestFormState();
  }

  /// Counts the times the form was built: once, then again each time the
  /// signed-in user changed.
  int _builds = 0;

  /// True when the form was built again since [builds] was read: an upload
  /// or a send that started under one user must leave the next user's form
  /// alone.
  ///
  /// With no screen on the form it is built again only when next read, so
  /// this reads it first: comparing the counter alone would say "the same
  /// form" for one that is about to be emptied.
  bool _rebuiltSince(int builds) {
    state;
    return builds != _builds;
  }

  /// Tells the form the company's days off, or null while they are not known
  /// (still loading, or the load failed): the counts that need them are then
  /// unknown, never guessed.
  ///
  /// The form on screen hands them in; this notifier does not listen for
  /// them itself. It outlives the screen (a draft is kept while the user
  /// looks elsewhere), and a listener here would keep the list alive across
  /// a sign-out, so the next login would be counted by the last one's
  /// company.
  void setDaysOff(CompanyDaysOff? daysOff) {
    if (daysOff == state.daysOff) return;
    state = state.copyWith(daysOff: daysOff);
  }

  /// Set when the server said the request this form edits is out of date
  /// (see [submit]). The next [seed] then fills the form again instead of
  /// keeping it. The form is not emptied at once: it is still on screen
  /// while its page closes, and would show a blank new-request form on the
  /// way out.
  bool _stale = false;

  /// The request the form was last filled from.
  LeaveRequest? _seededFrom;

  /// Fills the form from an existing request (edit mode). Safe to call once,
  /// from the edit page's initState: a form already in edit mode is kept,
  /// unless it was marked out of date.
  void seed(LeaveRequest request) {
    // Kept only while it was filled from this same request. If the request
    // has changed since (HR edited it, the page reloaded), a draft made on
    // the old one would be saved over days the user never saw.
    if (state.isEditing && !_stale && request == _seededFrom) return;
    _stale = false;
    _seededFrom = request;
    _form++;
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
      originalDaysByYear: _daysByYear(request, days),
      files: request.attachments,
    );
  }

  /// How many days [request] has in each year: each of its [days] is
  /// charged to its own year. A half day is the one day's half. A request
  /// that came without its days is counted whole in the year it starts.
  static Map<int, double> _daysByYear(
    LeaveRequest request,
    List<DateTime> days,
  ) {
    if (days.isEmpty) return {request.startDate.year: request.totalDays};
    if (request.durationType.isHalfDay) return {days.first.year: 0.5};

    final byYear = <int, double>{};
    for (final day in days) {
      byYear[day.year] = (byYear[day.year] ?? 0) + 1;
    }
    return byYear;
  }

  /// Uploads [file] (`POST /uploads`, folder `leave`) and adds it to the
  /// request's files. Nothing is sent while it runs. A failure is kept in
  /// `fileFailure`, and the files stay as they were.
  ///
  /// An upload that answers after the form was filled again (another
  /// request, or emptied after a send) is dropped: it belongs to a form
  /// that is gone.
  ///
  /// Not while the request is being sent: the save has gone out without
  /// it, and the file would land on a form that no longer matches.
  Future<void> addFile(LocalFile file) async {
    if (state.submission.isLoading) return;
    final form = _form;
    final builds = _builds;
    state = state.copyWith(
      uploadingFiles: state.uploadingFiles + 1,
      fileFailure: null,
    );
    final result = await ref.read(uploadAttachmentUseCaseProvider)((
      file: file,
      folder: UploadFolder.leave,
    ));
    if (_rebuiltSince(builds) || form != _form) return;
    state = result.fold(
      (failure) => state.copyWith(
        uploadingFiles: _less(state.uploadingFiles),
        fileFailure: failure,
      ),
      (uploaded) => state.copyWith(
        uploadingFiles: _less(state.uploadingFiles),
        files: [...state.files, _asLeaveFile(uploaded)],
        filesChanged: true,
      ),
    );
  }

  /// Counts the times the form was filled anew (seeded, emptied after a
  /// send, or built again), so a late upload can tell its form is gone.
  int _form = 0;

  /// Takes the file at [index] off the request.
  void removeFile(int index) {
    if (state.submission.isLoading) return;
    if (index < 0 || index >= state.files.length) return;
    state = state.copyWith(
      files: [...state.files]..removeAt(index),
      filesChanged: true,
    );
  }

  static int _less(int count) => count > 0 ? count - 1 : 0;

  static LeaveAttachment _asLeaveFile(UploadedAttachment uploaded) =>
      LeaveAttachment(
        fileName: uploaded.fileName,
        originalName: uploaded.originalName,
        url: uploaded.url,
        contentType: uploaded.contentType,
        size: uploaded.size,
      );

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
      typeRefused: false,
      balanceRefusedYear: null,
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
        balanceRefusedYear: null,
      );
      return;
    }

    final picked = [...state.dates]..sort();
    state = state.copyWith(
      mode: mode,
      rangeStart: picked.isEmpty ? null : picked.first,
      rangeEnd: picked.isEmpty ? null : picked.last,
      dates: const [],
      balanceRefusedYear: null,
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
      balanceRefusedYear: null,
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
      balanceRefusedYear: null,
    );
  }

  void removeDate(DateTime date) {
    state = state.copyWith(
      dates: state.dates.where((d) => d != date).toList(),
      balanceRefusedYear: null,
    );
  }

  /// A half day is exactly one date, so choosing one moves the form to
  /// separate days and keeps the earliest day picked so far.
  void setDurationType(LeaveDurationType type) {
    if (!type.isHalfDay) {
      state = state.copyWith(durationType: type, balanceRefusedYear: null);
      return;
    }

    // The first day that would be charged. A range of days off only has
    // none, and its first day is not offered in its place: sent as a
    // separate day it would be charged. With the days off unknown the
    // range's own first day is the best there is.
    final charged = state.chargedDays;
    final first = charged == null
        ? state.firstLeaveDate
        : (charged.isEmpty ? null : charged.first);
    final dates = first == null ? const <DateTime>[] : [first];
    // A return date picked by hand was for the days now cut: it goes, and
    // the form's own one (the day after) takes its place. Days that are not
    // known (a range, days off unknown) count as cut.
    final before = state.chargedDays;
    final sameDays = before != null && listEquals(before, dates);
    state = state.copyWith(
      durationType: type,
      mode: LeaveDaysMode.separateDays,
      dates: dates,
      rangeStart: null,
      rangeEnd: null,
      returnToWorkOverride: sameDays ? state.returnToWorkOverride : null,
      balanceRefusedYear: null,
    );
  }

  void setReturnToWorkDate(DateTime date) =>
      state = state.copyWith(returnToWorkOverride: date);

  void setReason(String reason) => state = state.copyWith(reason: reason);

  /// True while the form still asks for what [sent] asked for: the same
  /// type, the same days, the same part of the day.
  bool _asksTheSame(LeaveRequestFormState sent) =>
      state.leaveTypeId == sent.leaveTypeId &&
      state.mode == sent.mode &&
      state.rangeStart == sent.rangeStart &&
      state.rangeEnd == sent.rangeEnd &&
      state.durationType == sent.durationType &&
      listEquals(state.dates, sent.dates);

  /// Submits (or, in edit mode, updates) the form. Returns whether it
  /// succeeded. A range in which every day is a company day off is not sent:
  /// the server would refuse it. On success a new request resets the form;
  /// both paths invalidate the history and balance lists so the reserved days
  /// refresh.
  Future<bool> submit() async {
    final leaveTypeId = state.leaveTypeId;
    if (leaveTypeId == null ||
        state.uploadingFiles > 0 ||
        state.submission.isLoading ||
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
      // A new request sends what is attached; an edit sends the whole list
      // only when it changed here, so the request's files are otherwise
      // left as they are.
      attachments: state.isEditing
          ? (state.filesChanged ? state.files : null)
          : (state.files.isEmpty ? null : state.files),
    );

    final editingId = state.editingRequestId;
    final builds = _builds;
    final sent = state;
    final result = editingId == null
        ? await ref.read(submitLeaveRequestUseCaseProvider)(draft)
        : await ref.read(updateLeaveRequestUseCaseProvider)((
            id: editingId,
            draft: draft,
          ));
    // Answered after its user signed out: the form is the next user's now,
    // and so are the lists. Nothing of this answer belongs on them.
    if (_rebuiltSince(builds)) return false;

    return result.fold(
      (failure) {
        state = state.copyWith(
          submission: AsyncValue.error(failure, StackTrace.current),
        );
        // The request being edited is not what this form shows any more (its
        // days changed, it was decided or cancelled, or it is gone). Saving
        // again would fail the same way: the lists reload, and the next edit
        // starts from the request as it then is. The form closes its page.
        // The server says a request is already waiting; the banner's check
        // may have failed earlier, so ask again.
        if (LeaveErrorCode.tokenOf(failure) ==
            LeaveErrorCode.tokenPendingRequestExists) {
          ref.invalidate(leavePendingRequestNotifierProvider);
        }
        // The type picked is switched off or gone: the user picks again
        // (the form does not pick for them), from a list asked for again. A
        // reload that fails leaves the list as it is. What was typed stays.
        // A half day on a type the server says takes whole days only: HR
        // changed the type since the list was read. The list is asked for
        // again, so the form offers a full day only (#14). The type itself
        // still stands, so nothing has to be picked again.
        if (LeaveRuleCode.tokenOf(failure) ==
            LeaveRuleCode.tokenHalfDayNotAllowed) {
          unawaited(
            ref
                .read(leaveTypesNotifierProvider.notifier)
                .reloadKeepingList(),
          );
        }
        if (LeaveRuleCode.isTypeRefused(failure)) {
          state = state.copyWith(typeRefused: true);
          unawaited(
            ref
                .read(leaveTypesNotifierProvider.notifier)
                .reloadKeepingList(),
          );
        }
        // Not enough days left: what the card showed was not what the
        // server counted with, so the balances are read again. When the
        // server names the short year, the card shows that one (#87).
        final shortYear = LeaveRuleCode.balanceYearOf(failure);
        if (shortYear != null ||
            LeaveErrorCode.tokenOf(failure) ==
                LeaveErrorCode.tokenInsufficientBalance) {
          // The year is kept only for the request as it was sent, and only
          // a year that request has a day in: the answer may land after the
          // user changed the days, and a year from nowhere is not shown.
          if (_asksTheSame(sent)) {
            state = state.copyWith(
              balanceRefusedYear: state.touchesYear(shortYear)
                  ? shortYear
                  : null,
            );
          }
          ref.invalidate(leaveBalancesNotifierProvider);
        }
        if (editingId != null && LeaveErrorCode.isStaleForOwner(failure)) {
          _stale = true;
          ref.invalidate(leaveHistoryNotifierProvider);
          ref.invalidate(leaveBalancesNotifierProvider);
          ref.invalidate(leavePendingRequestNotifierProvider);
        }
        return false;
      },
      (request) {
        if (editingId == null) {
          _form++;
          state = LeaveRequestFormState(daysOff: state.daysOff);
        } else {
          state = state.copyWith(
            submission: AsyncValue.data(request),
            balanceRefusedYear: null,
          );
        }
        ref.invalidate(leaveHistoryNotifierProvider);
        ref.invalidate(leaveBalancesNotifierProvider);
        // A new request is now the one waiting; an edit may have changed it.
        ref.invalidate(leavePendingRequestNotifierProvider);
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
