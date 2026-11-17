import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/validation_codes.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/upload/domain/uploaded_attachment.dart';
import '../../../profile/domain/entities/shift_detail.dart';
import '../correction_rules.dart';
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

  /// The chosen shift part itself, for its window (#43). Not sent: only its
  /// id goes on the wire. Null when not known (the server then decides).
  final ShiftDetail? part;

  const TimeCorrectionRequest({
    required this.date,
    required this.type,
    required this.shiftDetailId,
    required this.clockIn,
    required this.clockOut,
    required this.reason,
    this.attachment,
    this.part,
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
        part: part,
      );

  /// Every rule the request breaks, keyed by [TimeCorrectionFields] and
  /// valued with a [ValidationCode]. Empty when it can be sent. [now] is
  /// injectable for tests.
  Map<String, String> violations({DateTime? now}) {
    final errors = <String, String>{};

    final range = CorrectionRules.lookBack(now ?? DateTime.now());
    final day = _dateOnly(date);
    if (day.isAfter(range.latest)) {
      errors[TimeCorrectionFields.date] = ValidationCode.correctionDateInFuture;
    } else if (day.isBefore(range.earliest)) {
      errors[TimeCorrectionFields.date] = ValidationCode.correctionDateTooOld;
    }

    final shiftId = shiftDetailId;
    if (shiftId == null || shiftId.isEmpty) {
      errors[TimeCorrectionFields.shift] =
          ValidationCode.correctionShiftRequired;
    }

    final timesError = CorrectionRules.check(
      type: type,
      clockIn: clockIn,
      clockOut: clockOut,
      part: part,
      date: day,
    );
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
    part,
  ];
}
