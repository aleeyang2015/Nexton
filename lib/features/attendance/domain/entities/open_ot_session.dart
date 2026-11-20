import 'package:equatable/equatable.dart';

/// The user's own OT that a clock-out would close now
/// (`GET /ot-sessions/open`): an OT clocked in on a day off or with a gap
/// from the shift, which `records/my` does not list; and, since 19 Nov 2026
/// (Nexton-Backend#298, #34), an OT run straight on from the shift with no
/// clock-in of its own, from the end of the shift's clock-out window to the
/// OT's end plus that window (past midnight too).
class OpenOtSession extends Equatable {
  final String overtimeRequestId;

  /// "OT 19:00–22:00", the server's own words.
  final String sessionLabel;

  /// When the OT was clocked in, and the last moment a clock-out still
  /// closes it; on the phone's clock.
  final DateTime? clockIn;
  final DateTime? clockOutUntil;

  const OpenOtSession({
    required this.overtimeRequestId,
    required this.sessionLabel,
    this.clockIn,
    this.clockOutUntil,
  });

  @override
  List<Object?> get props => [
    overtimeRequestId,
    sessionLabel,
    clockIn,
    clockOutUntil,
  ];
}
