import 'package:equatable/equatable.dart';

/// The user's own OT clock-in that a clock-out would close now
/// (`GET /ot-sessions/open`): an OT on a day off or with a gap from the
/// shift, which `records/my` does not list.
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
