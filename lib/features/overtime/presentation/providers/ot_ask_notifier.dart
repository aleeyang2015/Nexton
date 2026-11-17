import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/clock_provider.dart';
import '../../domain/entities/ot_draft.dart';
import '../../domain/entities/ot_request.dart';
import '../../overtime_providers.dart';
import 'ot_ask_state.dart';
import 'ot_list_notifier.dart';

/// The Ask OT form (`POST /ot-requests`). The page renders the state and
/// forwards picks and taps here.
///
/// No backend rule is checked here (days back, the shift, the OT switch):
/// the server decides, and its refusal is kept for the page to say.
///
/// AutoDispose, so leaving the page drops what was typed.
class OtAskNotifier extends AutoDisposeNotifier<OtAskState> {
  bool _disposed = false;

  @override
  OtAskState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    final now = ref.read(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    return OtAskState(workDate: today, today: today);
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

  /// Sends the form. Returns the new request when the server saved it,
  /// for the page to open; null when nothing was sent (both times not yet
  /// picked, or already sending) or the server refused it. A refusal keeps
  /// everything typed.
  Future<OtRequest?> submit() async {
    final start = state.startTime;
    final end = state.endTime;
    if (!state.canSend || start == null || end == null) return null;

    state = state.copyWith(sending: true, endError: false, clearRefusal: true);
    final reason = state.reason.trim();
    final result = await ref.read(askOtUseCaseProvider)(
      OtDraft(
        workDate: state.workDate,
        startTime: start,
        endTime: end,
        reason: reason.isEmpty ? null : reason,
      ),
    );
    if (_disposed) return result.dataOrNull;

    return result.fold(
      (failure) {
        state = _isEndError(failure)
            ? state.copyWith(sending: false, endError: true)
            : state.copyWith(sending: false, refusal: failure);
        return null;
      },
      (request) {
        state = state.copyWith(sending: false);
        // The list underneath shows the new request when the user comes
        // back to it.
        if (ref.exists(otListNotifierProvider)) {
          ref.read(otListNotifierProvider.notifier).refresh();
        }
        return request;
      },
    );
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

final otAskNotifierProvider =
    NotifierProvider.autoDispose<OtAskNotifier, OtAskState>(
      OtAskNotifier.new,
    );
