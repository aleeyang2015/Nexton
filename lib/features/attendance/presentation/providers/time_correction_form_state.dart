import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../profile/domain/entities/shift_detail.dart';
import '../../domain/entities/time_correction_request.dart';
import '../../domain/entities/time_correction_type.dart';
import '../../domain/correction_rules.dart';
import '../../../../core/errors/validation_codes.dart';

part 'time_correction_form_state.freezed.dart';

/// The time-correction request form's fields. [shiftDetail] is the segment of
/// the employee's assigned shift the correction is filed against. The
/// evidence file lives in [timeCorrectionAttachmentNotifierProvider], which
/// uploads it as soon as it is picked.
///
/// Field errors stay hidden until the first submit attempt ([showErrors]),
/// so an untouched form doesn't open covered in red.
@freezed
class TimeCorrectionFormState with _$TimeCorrectionFormState {
  const TimeCorrectionFormState._();

  /// Longest reason the form accepts.
  static const int reasonMaxLength = AppConstants.timeCorrectionReasonMaxLength;

  const factory TimeCorrectionFormState({
    required DateTime date,
    @Default(TimeCorrectionType.both) TimeCorrectionType type,
    ShiftDetail? shiftDetail,
    @Default(TimeOfDay(hour: 8, minute: 0)) TimeOfDay clockIn,
    @Default(TimeOfDay(hour: 17, minute: 0)) TimeOfDay clockOut,
    @Default('') String reason,
    @Default(false) bool showErrors,
    /// How the last send went; once sent, the new request's id (null when
    /// the answer carried none, or before any send).
    @Default(AsyncValue<String?>.data(null)) AsyncValue<String?> submission,
  }) = _TimeCorrectionFormState;

  /// The form as the domain request it submits.
  TimeCorrectionRequest toRequest() => TimeCorrectionRequest(
    date: date,
    type: type,
    shiftDetailId: shiftDetail?.id,
    clockIn: Duration(hours: clockIn.hour, minutes: clockIn.minute),
    clockOut: Duration(hours: clockOut.hour, minutes: clockOut.minute),
    reason: reason,
    part: shiftDetail,
  );

  /// The chosen part's window on [date] (#43), for the "outside the part
  /// (from–to)" text; null when the part's times are not known.
  CorrectionWindow? get window {
    final part = shiftDetail;
    return part == null ? null : CorrectionRules.window(part, date);
  }

  /// The [ValidationCode] for [field] (a [TimeCorrectionFields] name), or
  /// null when it is fine or errors aren't shown yet.
  ///
  /// The clock-in/out order is the exception: it shows as soon as it breaks,
  /// since it only ever comes from a pick the user just made. A time outside
  /// the part waits for Send like the rest: the form must not open in red.
  String? errorFor(String field) {
    final code = toRequest().violations()[field];
    if (showErrors) return code;
    return field == TimeCorrectionFields.times &&
            code == ValidationCode.correctionInvalidTimes
        ? code
        : null;
  }

  bool get isSubmitting => submission.isLoading;
}
