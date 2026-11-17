import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/clock_provider.dart';
import '../../domain/entities/ot_draft.dart';
import '../../domain/entities/ot_request.dart';
import '../../data/datasources/ot_error_code.dart';
import '../../domain/usecases/edit_ot_usecase.dart';
import '../../overtime_providers.dart';
import 'ot_ask_state.dart';
import 'ot_detail_notifier.dart';
import 'ot_list_notifier.dart';

/// The OT form: asking (`POST /ot-requests`, the family's argument null)
/// or changing a waiting request (`PUT /ot-requests/:id`, the argument is
/// that request, its day, times and reason filled in). The page renders the
/// state and forwards picks and taps here.
///
/// No backend rule is checked here (days back, the shift, the OT switch,
/// whether it may still be changed): the server decides, and its refusal is
/// kept for the page to say.
///
/// AutoDispose, so leaving the page drops what was typed.
class OtAskNotifier extends AutoDisposeFamilyNotifier<OtAskState, OtRequest?> {
  bool _disposed = false;

  /// The request being changed, or null when asking.
  OtRequest? get editing => arg;

  @override
  OtAskState build(OtRequest? arg) {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    final now = ref.read(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    if (arg == null) return OtAskState(workDate: today, today: today);
    return OtAskState(
      workDate: arg.workDate ?? today,
      today: today,
      startTime: _asSent(arg.startTime),
      endTime: _asSent(arg.endTime),
      reason: arg.reason ?? '',
    );
  }

  void setDate(DateTime date) =>
      _edit(state.copyWith(workDate: DateTime(date.year, date.month, date.day)));

  void setStart(int hour, int minute) =>
      _edit(state.copyWith(startTime: _hhmm(hour, minute)));

  void setEnd(int hour, int minute) =>
      _edit(state.copyWith(endTime: _hhmm(hour, minute)));

  /// The reason: the last refusal stays (a reason does not change why the
  /// server said no).
  void setReason(String reason) => _edit(
    state.copyWith(reason: reason),
    keepRefusal: true,
  );

  /// Sends the form. Returns the request as the server saved it (new, or
  /// changed), for the page to show; null when nothing was sent (both times
  /// not yet picked, or already sending) or the server refused it. A
  /// refusal keeps everything typed.
  ///
  /// Changing: the request page underneath shows the answer at once (and
  /// keeps the list's row with it). A refusal that says the request may no
  /// longer change ([isTooLate]) or is gone ([isGone]) reloads that page,
  /// so its buttons go or it learns it is gone.
  Future<OtRequest?> submit() async {
    final start = state.startTime;
    final end = state.endTime;
    if (!state.canSend || start == null || end == null) return null;

    state = state.copyWith(sending: true, endError: false, clearRefusal: true);
    final reason = state.reason.trim();
    final draft = OtDraft(
      workDate: state.workDate,
      startTime: start,
      endTime: end,
      reason: reason.isEmpty ? null : reason,
    );
    final editing = this.editing;
    final result = editing == null
        ? await ref.read(askOtUseCaseProvider)(draft)
        : await ref.read(editOtUseCaseProvider)(
            EditOtParams(id: editing.id, draft: draft),
          );
    if (_disposed) return result.dataOrNull;

    return result.fold(
      (failure) {
        state = _isEndError(failure)
            ? state.copyWith(sending: false, endError: true)
            : state.copyWith(sending: false, refusal: failure);
        if (editing != null && (isTooLate(failure) || isGone(failure))) {
          _detail(editing.id)?.refresh();
        }
        return null;
      },
      (request) {
        state = state.copyWith(sending: false);
        if (editing != null) {
          _detail(editing.id)?.replace(request);
        } else if (ref.exists(otListNotifierProvider)) {
          // The list underneath shows the new request when the user comes
          // back to it.
          ref.read(otListNotifierProvider.notifier).refresh();
        }
        return request;
      },
    );
  }

  /// The request page of [id], when it is open underneath.
  OtDetailNotifier? _detail(String id) {
    final provider = otDetailNotifierProvider(id);
    return ref.exists(provider) ? ref.read(provider.notifier) : null;
  }

  /// The request may no longer be changed: a step was decided meanwhile
  /// (`OT_ALREADY_DECIDED`), or it is a join of an HR post (`OT_ANNOUNCED`).
  static bool isTooLate(Failure? failure) =>
      failure is ValidationFailure &&
      (failure.message == OtErrorCode.tokenAlreadyDecided ||
          failure.message == OtErrorCode.tokenAnnounced);

  /// The request is gone, or not the caller's (`404`).
  static bool isGone(Failure? failure) => OtDetailNotifier.isGone(failure);

  /// `18:00` from `18:00` or `18:00:00`; null for anything that is not a
  /// time, so the user picks it again.
  static String? _asSent(String time) {
    final match = RegExp(r'^(\d{2}):(\d{2})').firstMatch(time);
    return match == null ? null : '${match[1]}:${match[2]}';
  }

  /// A change to the form: the last refusal and End error no longer apply
  /// (but for a change to the reason alone). Today is read again, so a form
  /// left open past midnight warns about a date that has since passed.
  void _edit(OtAskState next, {bool keepRefusal = false}) {
    if (state.sending) return;
    final now = ref.read(clockProvider)();
    state = OtAskState(
      workDate: next.workDate,
      today: DateTime(now.year, now.month, now.day),
      startTime: next.startTime,
      endTime: next.endTime,
      reason: next.reason,
      endError: keepRefusal ? next.endError : false,
      refusal: keepRefusal ? next.refusal : null,
    );
  }

  /// The server's `422` on `end_time`: the end equals the start.
  static bool _isEndError(Failure failure) =>
      failure is ValidationFailure && failure.field == 'end_time';

  static String _hhmm(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// The OT form: `otAskNotifierProvider(null)` to ask,
/// `otAskNotifierProvider(request)` to change that request.
final otAskNotifierProvider = NotifierProvider.autoDispose
    .family<OtAskNotifier, OtAskState, OtRequest?>(OtAskNotifier.new);
