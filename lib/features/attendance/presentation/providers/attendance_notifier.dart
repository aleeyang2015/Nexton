import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../attendance_providers.dart';
import '../../domain/attendance_failure_x.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/clock_method.dart';
import '../../domain/entities/punch_outcome.dart';
import '../../domain/entities/punch_request.dart';
import 'attendance_state.dart';

/// Owns every attendance behaviour the home screen can trigger. The card and
/// the page forward events here and render what comes back; neither holds
/// attendance logic of its own.
class AttendanceNotifier extends Notifier<AttendanceState> {
  /// How long the slide action stays inert after a 429.
  ///
  /// The backend's own window isn't published, and `Retry-After` is gone by
  /// the time the transport error has been mapped to a `Failure`, so this is
  /// a deliberately conservative local guess — long enough to stop a user
  /// drumming on the control, short enough not to strand a genuine punch.
  static const Duration throttleCooldown = Duration(seconds: 30);

  /// The method the slide action punches with. GPS is the spec's primary
  /// flow; the card's method row is display-only until the user can pick.
  static const ClockMethod defaultMethod = ClockMethod.gps;

  Timer? _cooldownTimer;

  /// The calendar day [state.today] was last fetched for, so a rollover past
  /// midnight can be noticed without a standing `Timer` — one created here
  /// would still be ticking, and so flagged as a leak, in any widget test
  /// that mounts the card but tears down its `ProviderContainer` itself
  /// (`UncontrolledProviderScope`, common across this app's widget tests)
  /// rather than by unmounting a `ProviderScope`.
  DateTime? _loadedDate;

  /// Re-reads today's record whenever the app comes back to the foreground.
  /// Without this, a session fetched before the phone was locked stays in
  /// memory verbatim — including one left open overnight by a missed
  /// clock-out — because this provider is never disposed just for being
  /// backgrounded.
  ///
  /// Null in a plain unit test, where nothing has initialised a Flutter
  /// binding for it to attach to; the notifier still works, it just has
  /// nothing to resume from.
  AppLifecycleListener? _lifecycleListener;

  /// The last request sent, kept so the early-checkout retry re-sends the
  /// *same* evidence instead of sampling a new position from wherever the
  /// phone has drifted to while the reason dialog was open.
  PunchRequest? _lastRequest;
  ClockAction? _lastAction;

  bool _disposed = false;

  @override
  AttendanceState build() {
    _disposed = false;
    _lifecycleListener = _tryCreateLifecycleListener();
    ref.onDispose(() {
      _disposed = true;
      _cooldownTimer?.cancel();
      _lifecycleListener?.dispose();
    });

    // Deferred past build: a Notifier may not write its own state while it is
    // being constructed.
    Future.microtask(loadToday);

    return const AttendanceState();
  }

  /// Guarded because this runs in plain `test()` suites too, where no
  /// `WidgetsBinding` exists for the listener to register with.
  AppLifecycleListener? _tryCreateLifecycleListener() {
    try {
      return AppLifecycleListener(onResume: () => unawaited(loadToday()));
    } catch (_) {
      return null;
    }
  }

  /// Fetches today's record so the card knows which punch is owed (§6.2).
  ///
  /// A failure here is not fatal — the card falls back to its resting state
  /// and the backend's session guard still catches a wrong guess — so the
  /// error is surfaced without blocking the control.
  Future<void> loadToday() async {
    if (_disposed) return;
    _loadedDate = _dateOnly(DateTime.now());
    state = state.copyWith(today: const AsyncValue.loading());

    final result = await ref.read(getTodayAttendanceUseCaseProvider)();
    if (_disposed) return;

    state = state.copyWith(
      today: result.fold(
        (failure) =>
            AsyncValue<AttendanceDay>.error(failure, StackTrace.current),
        (day) => AsyncValue<AttendanceDay>.data(day),
      ),
    );
  }

  /// Re-reads today's record if the calendar day has moved on since the last
  /// load — the card's live clock calls this every second, so a day left
  /// open on screen (the app foregrounded the whole time, never backgrounded)
  /// still rolls over without needing a standing `Timer` of its own.
  void refreshIfNewDay() {
    if (_disposed || state.isLoadingToday) return;
    final loaded = _loadedDate;
    if (loaded != null && loaded != _dateOnly(DateTime.now())) {
      unawaited(loadToday());
    }
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Sends the punch the day currently owes — clock-in, or clock-out once a
  /// session is open.
  ///
  /// Returns `null` when the press was suppressed: a punch is already in
  /// flight, or a 429 cooldown is still running. That is the debounce §7 rule
  /// 8 asks for, and it is reported as "nothing happened" rather than as a
  /// failure, because nothing did.
  Future<Result<PunchOutcome>?> punch({
    ClockMethod method = defaultMethod,
    String? fieldWorkReason,
    String? notes,
  }) async {
    if (!state.canPunch) return null;

    final action = state.nextAction;
    state = state.copyWith(isPunching: true);

    try {
      final prepared = await ref.read(preparePunchUseCaseProvider)(
        method,
        fieldWorkReason: fieldWorkReason,
        notes: notes,
      );
      if (_disposed) return null;

      final request = prepared.dataOrNull;
      if (request == null) {
        return Result.failure(prepared.failureOrNull!);
      }

      return await _send(action, request);
    } finally {
      if (!_disposed) state = state.copyWith(isPunching: false);
    }
  }

  /// Re-sends the punch that was refused for want of a justification, with
  /// the reason the user just typed (§4 rule 4, §7 rule 6).
  ///
  /// Reuses the stored request, so the retry carries the original reading.
  /// Returns `null` when there is nothing to retry or the control is still
  /// suppressed.
  Future<Result<PunchOutcome>?> retryWithReason(String reason) async {
    final request = _lastRequest;
    final action = _lastAction;
    if (request == null || action == null) return null;
    if (!state.canPunch) return null;

    state = state.copyWith(isPunching: true);
    try {
      return await _send(action, request.copyWith(notes: reason));
    } finally {
      if (!_disposed) state = state.copyWith(isPunching: false);
    }
  }

  Future<Result<PunchOutcome>> _send(
    ClockAction action,
    PunchRequest request,
  ) async {
    _lastRequest = request;
    _lastAction = action;

    final result = await switch (action) {
      ClockAction.clockIn => ref.read(clockInUseCaseProvider)(request),
      ClockAction.clockOut => ref.read(clockOutUseCaseProvider)(request),
    };

    if (_disposed) return result;

    result.fold(_applyFailure, _applyOutcome);
    return result;
  }

  void _applyOutcome(PunchOutcome outcome) {
    switch (outcome) {
      // A stored punch changed the day — including a `rejected` one, which is
      // still a log the backend now holds. Re-read rather than guess, so the
      // card shows what the server actually recorded.
      case PunchRecorded():
        unawaited(loadToday());

      // A refusal changed nothing server-side, with one exception: being told
      // the session is already open (or already closed) means our idea of the
      // day was stale, so it is worth re-reading.
      case PunchBlocked(:final rule):
        if (_rulesImplyingStaleDay.contains(rule)) unawaited(loadToday());
    }
  }

  void _applyFailure(Failure failure) {
    if (failure.isThrottled) _startCooldown();
  }

  /// Refusals that mean the card's picture of today is out of date.
  static const Set<AttendanceRule> _rulesImplyingStaleDay = {
    AttendanceRule.sessionAlreadyStarted,
    AttendanceRule.sessionAlreadyCompleted,
    AttendanceRule.sessionAlreadyCheckedOut,
    AttendanceRule.sessionNotStarted,
  };

  void _startCooldown() {
    final until = DateTime.now().add(throttleCooldown);
    state = state.copyWith(cooldownUntil: until);

    // The cooldown is a computed property, so the card needs a nudge to
    // re-render once the window closes.
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(throttleCooldown, () {
      if (_disposed) return;
      state = state.copyWith(cooldownUntil: null);
    });
  }
}

final attendanceNotifierProvider =
    NotifierProvider<AttendanceNotifier, AttendanceState>(
      AttendanceNotifier.new,
    );
