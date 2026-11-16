import 'package:equatable/equatable.dart';

/// A file accepted by `POST /uploads`, echoed back verbatim by the endpoint.
///
/// Held in the leave form's attachment slot and embedded — unchanged — in the
/// request body's `attachments` object (leave-request-flutter.md §3.3). Kept
/// separate from [LeaveAttachment] (which renders attachments already on a
/// request) because the submit round-trip needs both the storage [fileName]
/// and the user-facing [originalName].
class UploadedAttachment extends Equatable {
  /// Public URL the backend stored the file at.
  final String url;

  /// The backend's storage key, e.g. `tenants/…/uploads/…_logo.jpg`.
  final String fileName;

  /// The name the file had on the user's device.
  final String originalName;
  final String? contentType;
  final int? size;

  const UploadedAttachment({
    required this.url,
    required this.fileName,
    required this.originalName,
    this.contentType,
    this.size,
  });

  @override
  List<Object?> get props => [url, fileName, originalName, contentType, size];
}
