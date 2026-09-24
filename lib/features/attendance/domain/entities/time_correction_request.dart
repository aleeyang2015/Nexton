import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/validation_codes.dart';
import '../../../../core/utils/result.dart';
import '../../../time_off/domain/entities/uploaded_attachment.dart';
import 'time_correction_type.dart';

/// Field names a [TimeCorrectionRequest] validation failure points at, so the
/// form can put the message under the right card.
class TimeCorrectionFields {
  TimeCorrectionFields._();

  static const String date = 'date';
  static const String shift = 'shift';
  static const String times = 'times';
  static const String reason = 'reason';
}

/// A time-correction request as `POST /attendance/correction-requests` takes
/// it — the "ລືມລົງເວລາ" form, already reduced to plain values.
///
/// [clockIn]/[clockOut] are times of day, held as the offset from midnight so
/// the domain stays free of Flutter's `TimeOfDay`. A time the [type] doesn't
/// need is ignored, whatever it holds.
class TimeCorrectionRequest extends Equatable {
  /// The day being corrected; only its date part is used.
  final DateTime date;
  final TimeCorrectionType type;

  /// The shift segment (`shift.shift_details[].id`) the correction is for.
  final String? shiftDetailId;
  final Duration? clockIn;
  final Duration? clockOut;
  final String reason;

  /// The evidence file, as `POST /uploads` accepted it.
  final UploadedAttachment? attachment;

  const TimeCorrectionRequest({
    required this.date,
    required this.type,
    required this.shiftDetailId,
    required this.clockIn,
    required this.clockOut,
    required this.reason,
    this.attachment,
  });

  TimeCorrectionRequest withAttachment(UploadedAttachment? file) =>
      TimeCorrectionRequest(
        date: date,
        type: type,
        shiftDetailId: shiftDetailId,
        clockIn: clockIn,
        clockOut: clockOut,
        reason: reason,
        attachment: file,
      );

  /// Every rule the request breaks, keyed by [TimeCorrectionFields] and
  /// valued with a [ValidationCode]. Empty when it can be sent. [now] is
  /// injectable for tests.
  Map<String, String> violations({DateTime? now}) {
    final errors = <String, String>{};

    final today = _dateOnly(now ?? DateTime.now());
    final day = _dateOnly(date);
    if (day.isAfter(today)) {
      errors[TimeCorrectionFields.date] = ValidationCode.correctionDateInFuture;
    } else if (today.difference(day).inDays >
        AppConstants.timeCorrectionMaxAgeDays) {
      errors[TimeCorrectionFields.date] = ValidationCode.correctionDateTooOld;
    }

    final shiftId = shiftDetailId;
    if (shiftId == null || shiftId.isEmpty) {
      errors[TimeCorrectionFields.shift] =
          ValidationCode.correctionShiftRequired;
    }

    final timesError = _timesError();
    if (timesError != null) errors[TimeCorrectionFields.times] = timesError;

    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      errors[TimeCorrectionFields.reason] =
          ValidationCode.correctionReasonRequired;
    } else if (trimmed.length > AppConstants.timeCorrectionReasonMaxLength) {
      errors[TimeCorrectionFields.reason] =
          ValidationCode.correctionReasonTooLong;
    }

    return errors;
  }

  /// The first broken rule as a [Failure], or success when there is none.
  Result<Unit> validate({DateTime? now}) {
    final errors = violations(now: now);
    if (errors.isEmpty) return const Result.success(Unit.instance);

    final first = errors.entries.first;
    return Result.failure(
      Failure.validation(message: first.value, field: first.key),
    );
  }

  String? _timesError() {
    final start = clockIn;
    final end = clockOut;
    if ((type.needsClockIn && start == null) ||
        (type.needsClockOut && end == null)) {
      return ValidationCode.correctionTimeRequired;
    }
    // Only comparable when the request carries both ends.
    if (start != null &&
        end != null &&
        type.needsClockIn &&
        type.needsClockOut &&
        end <= start) {
      return ValidationCode.correctionInvalidTimes;
    }
    return null;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  List<Object?> get props => [
    date,
    type,
    shiftDetailId,
    clockIn,
    clockOut,
    reason,
    attachment,
  ];
}
