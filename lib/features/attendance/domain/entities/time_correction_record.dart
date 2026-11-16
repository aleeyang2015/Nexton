import 'package:equatable/equatable.dart';

import 'time_correction_status.dart';
import 'time_correction_type.dart';

/// A time-correction request the employee has already filed — one card on
/// the "ປະຫວັດການຮ້ອງຂໍແກ້ໄຂເວລາ" page.
///
/// [clockIn]/[clockOut] are offsets from midnight, as on
/// [TimeCorrectionRequest]; a time the [type] doesn't carry is null.
class TimeCorrectionRecord extends Equatable {
  final String id;

  /// When the request was sent.
  final DateTime submittedAt;

  /// The day being corrected.
  final DateTime workDate;
  final TimeCorrectionType type;
  final Duration? clockIn;
  final Duration? clockOut;
  final TimeCorrectionStatus status;
  final int attachmentCount;

  const TimeCorrectionRecord({
    required this.id,
    required this.submittedAt,
    required this.workDate,
    required this.type,
    required this.clockIn,
    required this.clockOut,
    required this.status,
    this.attachmentCount = 0,
  });

  @override
  List<Object?> get props => [
    id,
    submittedAt,
    workDate,
    type,
    clockIn,
    clockOut,
    status,
    attachmentCount,
  ];
}
