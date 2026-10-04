import '../../../time_off/data/models/uploaded_attachment_model.dart';
import '../../domain/entities/offsite_request.dart';

/// Serialises an [OffsiteRequest] into the
/// `POST /attendance/offsite-requests` body (§3).
///
/// Three things the endpoint is particular about:
/// - `employee_id` is never sent — it comes from the JWT, and §1 forbids it in
///   the body;
/// - the scan time is never sent either, for the same reason;
/// - `attachments` is plural but holds a **single object**, not an array (§3
///   note 3), and carries the `POST /uploads` response verbatim.
class OffsiteRequestBody {
  final OffsiteRequest request;

  const OffsiteRequestBody(this.request);

  Map<String, dynamic> toJson() {
    final attachment = request.attachment;

    return {
      'method': request.method.wireValue,
      'latitude': request.latitude,
      'longitude': request.longitude,
      'reason': request.reason.trim(),
      if (attachment != null)
        'attachments': UploadedAttachmentModel.toJson(attachment),
    };
  }
}
