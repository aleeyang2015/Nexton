import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../time_off/domain/entities/local_file.dart';
import '../../domain/entities/time_correction_type.dart';
import '../../domain/entities/work_shift.dart';

part 'time_correction_form_state.freezed.dart';

/// The time-correction request form's fields. [attachment] is a file picked
/// off the device (not yet uploaded) and [attachmentBytes] its size, for the
/// "(1.2 MB)" label.
@freezed
class TimeCorrectionFormState with _$TimeCorrectionFormState {
  const TimeCorrectionFormState._();

  /// Longest reason the form accepts.
  static const int reasonMaxLength = 200;

  /// Largest attachment the form accepts, in bytes (5 MB).
  static const int attachmentMaxBytes = 5 * 1024 * 1024;

  const factory TimeCorrectionFormState({
    required DateTime date,
    @Default(TimeCorrectionType.both) TimeCorrectionType type,
    WorkShift? shift,
    @Default(TimeOfDay(hour: 8, minute: 0)) TimeOfDay clockIn,
    @Default(TimeOfDay(hour: 17, minute: 0)) TimeOfDay clockOut,
    @Default('') String reason,
    LocalFile? attachment,
    int? attachmentBytes,
  }) = _TimeCorrectionFormState;

  /// Clock-out must come after clock-in when the request carries both.
  bool get hasValidTimes {
    if (!type.needsClockIn || !type.needsClockOut) return true;
    return clockOut.hour * 60 + clockOut.minute >
        clockIn.hour * 60 + clockIn.minute;
  }

  bool get canSubmit =>
      shift != null && reason.trim().isNotEmpty && hasValidTimes;
}
