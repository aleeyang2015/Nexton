import 'package:dio/dio.dart';

import '../../network/api_client.dart';
import '../../network/api_response.dart';
import '../domain/local_file.dart';
import '../domain/uploaded_attachment.dart';

/// The generic file-upload call (`POST /uploads`), relative to the client's
/// `/api/v1` base URL.
///
/// The endpoint takes exactly one file per request (`form-data` field `file`)
/// and answers with a single `data` object.
abstract class UploadRemoteDataSource {
  Future<UploadedAttachment> upload(LocalFile file);
}

class UploadRemoteDataSourceImpl implements UploadRemoteDataSource {
  /// Generic on purpose — not under `/core_hr/leave` — so it stays reusable if
  /// another feature ever needs the same endpoint.
  static const String _path = '/uploads';

  /// The `form-data` field the backend reads the file from (singular).
  static const String _field = 'file';

  final ApiClient _client;

  UploadRemoteDataSourceImpl(this._client);

  @override
  Future<UploadedAttachment> upload(LocalFile file) async {
    final formData = FormData.fromMap({
      _field: await MultipartFile.fromFile(
        file.path,
        filename: file.name,
        contentType: _mediaType(file.name),
      ),
    });

    final response = await _client.upload<dynamic>(_path, formData);

    final attachment = _attachment(ApiEnvelope.unwrapObject(response.data));
    if (attachment == null) {
      throw const FormatException('Upload response carried no file url');
    }
    return attachment;
  }

  /// The `Content-Type` for the part, from the file's extension.
  /// `MultipartFile` otherwise sends everything as `application/octet-stream`,
  /// which some backends reject for Office documents. Falls back to null
  /// (octet-stream) for anything unlisted — the picker already limits the set.
  static DioMediaType? _mediaType(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0) return null;
    final mime = _mimeByExtension[fileName.substring(dot + 1).toLowerCase()];
    return mime == null ? null : DioMediaType.parse(mime);
  }

  static const Map<String, String> _mimeByExtension = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'bmp': 'image/bmp',
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx':
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  };

  /// Reads the `data` object of an upload response:
  /// `{ url, file_name, original_name, content_type, size }`. `file_name` is
  /// the storage key; `original_name` is the user's filename.
  static UploadedAttachment? _attachment(Map<String, dynamic> json) {
    final url =
        _text(json['url']) ?? _text(json['path']);
    if (url == null) return null;
    final fileName = _text(json['file_name']) ?? url;
    return UploadedAttachment(
      url: url,
      fileName: fileName,
      originalName:
          _text(json['original_name']) ??
          _text(json['name']) ??
          fileName,
      contentType:
          _text(json['content_type']) ??
          _text(json['mime_type']),
      size: _int(json['size']),
    );
  }

  static String? _text(dynamic value) =>
      value is String && value.isNotEmpty ? value : null;

  static int? _int(dynamic value) => value is num ? value.toInt() : null;
}
