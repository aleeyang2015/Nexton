import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../time_off/domain/entities/uploaded_attachment.dart';
import '../../domain/datasources/punch_location_source.dart';
import '../../domain/entities/offsite_method.dart';
import '../../domain/entities/offsite_request.dart';

part 'offsite_form_state.freezed.dart';

/// The off-site scan request form's fields.
///
/// [location] is read from the device when the form opens and can be re-read
/// from the card; its error carries the reason (services off, permission
/// denied, no fix), which is why it is held as an [AsyncValue] rather than a
/// bare pair of doubles. [photo] mirrors the file
/// [offsitePhotoNotifierProvider] has uploaded, so the form can refuse to
/// submit without one — §3 makes the photo required.
///
/// Field errors stay hidden until the first submit attempt ([showErrors]), so
/// an untouched form doesn't open covered in red.
@freezed
class OffsiteFormState with _$OffsiteFormState {
  const OffsiteFormState._();

  /// Longest reason the form accepts.
  static const int reasonMaxLength = AppConstants.offsiteReasonMaxLength;

  const factory OffsiteFormState({
    /// Which punch the scan stands in for. Set when the form opens — to the
    /// direction of the punch that was just refused, when the employee got here
    /// from one — and switchable on the form.
    required OffsiteMethod method,
    @Default(AsyncValue<PunchLocationReading>.loading())
    AsyncValue<PunchLocationReading> location,
    @Default('') String reason,
    UploadedAttachment? photo,
    @Default(false) bool showErrors,
    @Default(AsyncValue<void>.data(null)) AsyncValue<void> submission,
  }) = _OffsiteFormState;

  /// The form as the domain request it submits.
  OffsiteRequest toRequest() {
    final reading = location.valueOrNull;
    return OffsiteRequest(
      method: method,
      latitude: reading?.latitude,
      longitude: reading?.longitude,
      reason: reason,
      attachment: photo,
    );
  }

  /// The [ValidationCode] for [field] (an [OffsiteFields] name), or null when
  /// it is fine or errors aren't shown yet.
  String? errorFor(String field) {
    if (!showErrors) return null;
    return toRequest().violations()[field];
  }

  bool get isSubmitting => submission.isLoading;

  /// True while the position is being read — submit waits for it rather than
  /// filing a request that is certain to be refused.
  bool get isLocating => location.isLoading;
}
