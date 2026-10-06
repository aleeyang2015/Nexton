import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/attendance_failure_x.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/offsite_method.dart';
import '../../domain/entities/punch_outcome.dart';
import '../providers/attendance_notifier.dart';
import 'attendance_copy.dart';
import 'early_checkout_reason_dialog.dart';
import 'punch_progress_dialog.dart';

/// Drives one press of the slide action from tap to feedback.
///
/// This is presentation routing, not business logic: every decision below is
/// about *which surface* an answer belongs on — a blocking dialog for
/// something the user must fix, a toast for something they only need to
/// know — following the error→UX table in §7. What the answer *is* was
/// decided in the domain and arrives here as a [PunchOutcome] or a [Failure].
class PunchFlow {
  PunchFlow._();

  /// Sends the punch the day owes and shows the result.
  static Future<void> start(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(attendanceNotifierProvider.notifier);
    final state = ref.read(attendanceNotifierProvider);

    // A cooldown from an earlier 429 is still running. Say so rather than
    // letting the control feel broken (§7 rule 10).
    if (state.isCoolingDown) {
      AppToast.info(AppLocalizations.of(context)!.clockCooldownActive);
      return;
    }

    // Captured before the punch: a successful clock-in flips `nextAction`,
    // and the message has to describe what was just done, not what is next.
    final action = state.nextAction;

    // Behind a blocking dialog: acquiring a fix and the round trip that
    // follows can take seconds, and the slider springs back immediately.
    final result = await PunchProgressDialog.runWhile(
      context,
      action,
      notifier.punch,
    );
    // Null means the press was swallowed by the in-flight guard — nothing
    // happened, so there is nothing to report.
    if (result == null || !context.mounted) return;

    await _handle(context, ref, result, action, allowRetry: true);
  }

  static Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    Result<PunchOutcome> result,
    ClockAction action, {
    required bool allowRetry,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    final failure = result.failureOrNull;
    if (failure != null) {
      return _handleFailure(context, ref, failure, l10n);
    }

    final outcome = result.dataOrNull;
    if (outcome == null) return;

    switch (outcome) {
      case PunchRecorded(:final receipt):
        final message = AttendanceCopy.receipt(l10n, receipt, action);

        // Logged, but outside every work area — the one rejection with a way
        // forward. Offer the off-site request instead of leaving the employee
        // with a warning and nothing to do about it.
        if (receipt.isOutsideWorkArea) {
          return _offerOffsiteRequest(
            context,
            action,
            message,
            l10n,
            recorded: true,
          );
        }

        // Stored-but-unverified is amber, never green (§7 rule 5).
        receipt.isVerified
            ? AppToast.success(message)
            : AppToast.warning(message);

      case PunchBlocked():
        await _handleBlocked(context, ref, outcome, action, l10n, allowRetry);
    }
  }

  static Future<void> _handleBlocked(
    BuildContext context,
    WidgetRef ref,
    PunchBlocked blocked,
    ClockAction action,
    AppLocalizations l10n,
    bool allowRetry,
  ) async {
    // The one refusal with a way forward: collect a reason and re-send the
    // same punch (§7 rule 6). `allowRetry` bounds it to a single attempt, so
    // a backend that kept asking could never trap the user in a loop.
    if (blocked.rule.isResolvableWithReason && allowRetry) {
      final reason = await EarlyCheckoutReasonDialog.show(
        context,
        blocked.details,
      );
      if (reason == null || !context.mounted) return;

      // The retry is another full round trip, so it gets the same dialog.
      final retried = await PunchProgressDialog.runWhile(
        context,
        action,
        () => ref
            .read(attendanceNotifierProvider.notifier)
            .retryWithReason(reason),
      );
      if (retried == null || !context.mounted) return;

      return _handle(context, ref, retried, action, allowRetry: false);
    }

    final message = AttendanceCopy.rule(l10n, blocked);

    // Refused for being out of area. The same situation reaches this method
    // down two different paths depending on how the backend answers — a
    // stored-but-rejected receipt above, an outright refusal here — and both
    // owe the employee the same way forward.
    if (blocked.rule.isResolvableOffsite) {
      // `success: false` with no `data` — the punch was refused, not stored,
      // so the offer must not claim it was recorded.
      return _offerOffsiteRequest(
        context,
        action,
        message,
        l10n,
        recorded: false,
      );
    }

    // Rules only HR or a device setting can clear deserve a dialog the user
    // has to acknowledge; the rest are informational.
    if (_needsAcknowledgement.contains(blocked.rule)) {
      return AppDialog.warning(context, message: message);
    }

    AppToast.warning(message);
  }

  static Future<void> _handleFailure(
    BuildContext context,
    WidgetRef ref,
    Failure failure,
    AppLocalizations l10n,
  ) async {
    // The session is already being torn down by the 401 interceptor and the
    // router is about to take the screen away — a message here would flash
    // and vanish.
    if (failure.isSessionFailure) return;

    final message = failure.localize(l10n);

    // The client refused to send the punch: GPS off, no BSSID, no reason.
    // That is something the user can act on, so it blocks.
    if (failure.isMissingEvidence) {
      return AppDialog.warning(context, message: message);
    }

    // A throttle is not retryable — the cooldown exists precisely to stop
    // another attempt (§7 rule 10).
    AppToast.error(
      message,
      actionLabel: failure.isRetryable ? l10n.retry : null,
      onAction: failure.isRetryable ? () => start(context, ref) : null,
    );
  }

  /// Asks whether to file an off-site scan for a punch that didn't count
  /// because the employee was out of area, and opens the form on a yes.
  ///
  /// Reached both from a stored-but-rejected receipt and from an outright
  /// refusal, so [warning] carries whichever wording the caller's path
  /// produced rather than being rebuilt here.
  ///
  /// [recorded] picks between the two: the documented 200 stores the punch
  /// and merely marks it unverified, while the deployed refusal writes
  /// nothing at all. Telling someone their punch was "recorded" when no row
  /// exists would leave them expecting a record that HR will never see.
  ///
  /// The punch itself is already logged — the backend stores a rejected punch —
  /// but a rejected one never becomes the day's record, so the scan request is
  /// how the time gets counted. The form opens on the direction that was just
  /// refused, so the request lands on the session the employee actually meant.
  ///
  /// Declining still gets the warning: the punch didn't pass its location
  /// check, and saying nothing would read as success.
  static Future<void> _offerOffsiteRequest(
    BuildContext context,
    ClockAction action,
    String warning,
    AppLocalizations l10n, {
    required bool recorded,
  }) async {
    final confirmed = await AppDialog.ask(
      context,
      title: l10n.offsiteOfferTitle,
      message: switch ((action, recorded)) {
        (ClockAction.clockIn, true) => l10n.offsiteOfferClockIn,
        (ClockAction.clockOut, true) => l10n.offsiteOfferClockOut,
        (ClockAction.clockIn, false) => l10n.offsiteOfferRefusedClockIn,
        (ClockAction.clockOut, false) => l10n.offsiteOfferRefusedClockOut,
      },
      confirmLabel: l10n.offsiteOfferConfirm,
    );
    if (!context.mounted) return;

    if (!confirmed) return AppToast.warning(warning);

    await context.push(
      AppRoutes.offsiteRequest,
      extra: OffsiteMethod.forAction(action),
    );
  }

  /// Refusals the user must read and act on elsewhere — contacting HR, or
  /// changing a device setting — rather than glance at.
  static const Set<AttendanceRule> _needsAcknowledgement = {
    AttendanceRule.mockLocationDetected,
    AttendanceRule.employeeNotFound,
    AttendanceRule.noShiftAssigned,
  };
}
