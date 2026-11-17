import 'package:equatable/equatable.dart';

import 'ot_piece.dart';
import 'ot_request.dart';

/// Whether an HR post can still be joined. A value the App does not know is
/// [unknown].
enum OtPostStatus { open, cancelled, unknown }

/// An HR OT post open to a department (`OTOpenAnnouncement`).
class OtPost extends Equatable {
  final String id;
  final String departmentId;
  final String? departmentName;

  /// The day the OT starts; [startTime] and [endTime] are the company's
  /// `HH:MM`, shown as sent.
  final DateTime? workDate;
  final String startTime;
  final String endTime;
  final bool endsNextDay;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// How many can join; null is no limit.
  final int? seats;

  /// The last moment to join; null is none.
  final DateTime? joinDeadline;
  final String? reason;
  final OtPostStatus status;

  /// How many have joined and been accepted, and how many wait.
  final int accepted;
  final int waiting;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<OtPiece> pieces;

  /// The server's own answers: every seat taken, and joining still allowed.
  final bool full;
  final bool joinOpen;

  /// The caller's own request for this post, or null when they have not
  /// joined.
  final OtRequest? myJoin;

  const OtPost({
    required this.id,
    required this.departmentId,
    this.departmentName,
    this.workDate,
    required this.startTime,
    required this.endTime,
    this.endsNextDay = false,
    this.startsAt,
    this.endsAt,
    this.seats,
    this.joinDeadline,
    this.reason,
    required this.status,
    this.accepted = 0,
    this.waiting = 0,
    this.createdAt,
    this.updatedAt,
    this.pieces = const [],
    this.full = false,
    this.joinOpen = false,
    this.myJoin,
  });

  /// False when anyone may join, however many.
  bool get hasSeatLimit => seats != null;

  @override
  List<Object?> get props => [
    id,
    departmentId,
    departmentName,
    workDate,
    startTime,
    endTime,
    endsNextDay,
    startsAt,
    endsAt,
    seats,
    joinDeadline,
    reason,
    status,
    accepted,
    waiting,
    createdAt,
    updatedAt,
    pieces,
    full,
    joinOpen,
    myJoin,
  ];
}
