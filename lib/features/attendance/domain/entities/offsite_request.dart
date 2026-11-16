import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/validation_codes.dart';
import '../../../../core/utils/result.dart';
import '../../../time_off/domain/entities/uploaded_attachment.dart';
import 'offsite_method.dart';

/// Field names an [OffsiteRequest] validation failure points at, so the form
/// can put the message under the right card.
class OffsiteFields {
  OffsiteFields._();

  static const String location = 'location';
  static const String reason = 'reason';
  static const String photo = 'attachments';
}

/// An off-site scan request as `POST /attendance/offsite-requests` takes it —
/// the "ລົງເວລານອກພື້ນທີ່" form, already reduced to plain values.
///
/// The scan *time* is deliberately absent: §3 says the server stamps it when
/// the request is filed and ignores anything the client sends, so the app
/// never gets to disagree about when the punch happened.
class OffsiteRequest extends Equatable {
  final OffsiteMethod method;

  /// Where the employee was standing. Both ends are required — §3 refuses a
  /// null either way — and a missing reading stays missing rather than
  /// becoming `0`, which would put them in the Gulf of Guinea.
  final double? latitude;
  final double? longitude;

  final String reason;

  /// The photo, as `POST /uploads` accepted it. Required here, unlike the
  /// time-correction form's optional evidence.
  final UploadedAttachment? attachment;

  const OffsiteRequest({
    required this.method,
    required this.latitude,
    required this.longitude,
    required this.reason,
    this.attachment,
  });

  OffsiteRequest withAttachment(UploadedAttachment? file) => OffsiteRequest(
    method: method,
    latitude: latitude,
    longitude: longitude,
    reason: reason,
    attachment: file,
  );

  bool get hasCoordinates => latitude != null && longitude != null;

  /// Every rule the request breaks, keyed by [OffsiteFields] and valued with a
  /// [ValidationCode]. Empty when it can be sent.
  ///
  /// These are §3's four `required` fields, checked here so the form never
  /// spends a round trip earning a 422 it could have predicted (the same
  /// client-side gate §11.2 asks for).
  Map<String, String> violations() {
    final errors = <String, String>{};

    if (!hasCoordinates) {
      // The *why* — services off, permission denied, no fix — is reported
      // when the position is read; by submit time all that is left to say is
      // that there isn't one.
      errors[OffsiteFields.location] = ValidationCode.locationUnavailable;
    }

    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      errors[OffsiteFields.reason] = ValidationCode.offsiteReasonRequired;
    } else if (trimmed.length > AppConstants.offsiteReasonMaxLength) {
      errors[OffsiteFields.reason] = ValidationCode.offsiteReasonTooLong;
    }

    // §3's note 2: the backend checks `url` and `file_name` a second time in
    // the handler, so an upload that came back without them is as good as no
    // photo at all.
    final file = attachment;
    if (file == null || file.url.isEmpty || file.fileName.isEmpty) {
      errors[OffsiteFields.photo] = ValidationCode.offsitePhotoRequired;
    }

    return errors;
  }

  /// The first broken rule as a [Failure], or success when there is none.
  Result<Unit> validate() {
    final errors = violations();
    if (errors.isEmpty) return const Result.success(Unit.instance);

    final first = errors.entries.first;
    return Result.failure(
      Failure.validation(message: first.value, field: first.key),
    );
  }

  @override
  List<Object?> get props => [method, latitude, longitude, reason, attachment];
}
