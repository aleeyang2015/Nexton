import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../profile/domain/entities/shift_detail.dart';
import '../../domain/entities/time_correction_request.dart';
import '../../domain/entities/time_correction_type.dart';

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
    @Default(AsyncValue<void>.data(null)) AsyncValue<void> submission,
  }) = _TimeCorrectionFormState;

  /// The form as the domain request it submits.
  TimeCorrectionRequest toRequest() => TimeCorrectionRequest(
    date: date,
    type: type,
    shiftDetailId: shiftDetail?.id,
    clockIn: Duration(hours: clockIn.hour, minutes: clockIn.minute),
    clockOut: Duration(hours: clockOut.hour, minutes: clockOut.minute),
    reason: reason,
  );

  /// The [ValidationCode] for [field] (a [TimeCorrectionFields] name), or
  /// null when it is fine or errors aren't shown yet.
  ///
  /// The clock-in/out order is the exception: it shows as soon as it breaks,
  /// since it only ever comes from a pick the user just made.
  String? errorFor(String field) {
    final code = toRequest().violations()[field];
    if (showErrors) return code;
    return field == TimeCorrectionFields.times ? code : null;
  }

  bool get isSubmitting => submission.isLoading;
}
