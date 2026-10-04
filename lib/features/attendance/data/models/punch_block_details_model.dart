import '../../domain/entities/punch_outcome.dart';

/// Lifts `error.details` out of a refusal envelope.
///
/// §7 rule 7 asks for these to be shown instead of generic copy ("clocking out
/// opens at 17:00"), so they are parsed rather than dropped. Shared by the
/// punch endpoints and the off-site scan request, which are refused by the same
/// session guard and so carry the same details.
class PunchBlockDetailsModel {
  const PunchBlockDetailsModel._();

  static PunchBlockDetails fromErrorBody(dynamic body) {
    if (body is! Map) return PunchBlockDetails.empty;

    final error = body['error'];
    if (error is! Map) return PunchBlockDetails.empty;

    final details = error['details'];
    if (details is! Map) return PunchBlockDetails.empty;

    final raw = Map<String, dynamic>.from(details);

    return PunchBlockDetails(
      sessionLabel: text(raw['session_label']),
      sessionOrder: (raw['session_order'] as num?)?.toInt(),
      earliestCheckout: text(raw['earliest_checkout']),
      latestCheckout: text(raw['latest_checkout']),
      // §5.2 spells this `next_session_*`; both spellings seen in the wild.
      nextSessionStart: text(
        raw['next_session_start'] ?? raw['next_session_starts'],
      ),
      lastShiftEnd: text(raw['last_shift_end']),
      endedAt: text(raw['ended_at']),
      nextStarts: text(raw['next_starts']),
      employeeId: text(raw['employee_id']),
      clockInOpens: text(raw['clock_in_opens']),
      raw: raw,
    );
  }

  /// Details values are interpolated straight into user copy, so a number or a
  /// timestamp is accepted as readily as a string.
  static String? text(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }
}
