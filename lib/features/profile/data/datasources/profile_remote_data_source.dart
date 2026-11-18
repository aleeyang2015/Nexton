import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/employee_profile.dart';
import '../../../../core/upload/domain/local_file.dart';
import '../models/employee_profile_model.dart';
import 'profile_api_paths.dart';
import 'profile_photo_error_code.dart';

/// The profile call the home header and the profile page can trigger.
///
/// Throws on failure ([AppException], or a [DioException] carrying a mapped
/// Failure); the repository converts those into a Result.
abstract class ProfileRemoteDataSource {
  Future<EmployeeProfile> myProfile();

  /// Replaces the photo of [employeeId] with [file] (#59): the new photo's
  /// URL. The server deletes the old one.
  Future<String> uploadPhoto(String employeeId, LocalFile file);
}

/// Reads the picked file into the multipart part. A seam so tests need no
/// file on disk.
typedef ReadPhotoPart =
    Future<MultipartFile> Function(LocalFile file, DioMediaType contentType);

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _client;
  final ReadPhotoPart _readPart;

  ProfileRemoteDataSourceImpl(this._client, {ReadPhotoPart? readPart})
    : _readPart = readPart ?? _fromDisk;

  static Future<MultipartFile> _fromDisk(
    LocalFile file,
    DioMediaType contentType,
  ) => MultipartFile.fromFile(
    file.path,
    filename: file.name,
    contentType: contentType,
  );

  /// The part must say `image/…`: `MultipartFile` would otherwise send
  /// `application/octet-stream`, which the server refuses. The picker only
  /// gives `jpg`, `jpeg` and `png`.
  static DioMediaType photoType(String fileName) =>
      fileName.toLowerCase().endsWith('.png')
      ? DioMediaType('image', 'png')
      : DioMediaType('image', 'jpeg');

  @override
  Future<String> uploadPhoto(String employeeId, LocalFile file) async {
    final form = FormData.fromMap({
      'photo': await _readPart(file, photoType(file.name)),
    });
    final Response<dynamic> response;
    try {
      response = await _client.put<dynamic>(
        ProfilePaths.photo(employeeId),
        data: form,
      );
    } on DioException catch (error) {
      final token = ProfilePhotoErrorCode.tokenForResponse(error);
      if (token != null) throw Failure.validation(message: token);
      rethrow;
    }
    // `{ "profile_photo_url": "<url>" }`, flat or in the usual envelope.
    String? url;
    try {
      final value = ApiEnvelope.unwrapObject(response.data)['profile_photo_url'];
      if (value is String && value.trim().isNotEmpty) url = value.trim();
    } on Object {
      url = null;
    }
    if (url == null) {
      throw const Failure.validation(
        message: ProfilePhotoErrorCode.tokenNotImage,
      );
    }
    return url;
  }

  @override
  Future<EmployeeProfile> myProfile() async {
    final response = await _client.get<dynamic>(ProfilePaths.me);
    return EmployeeProfileModel.fromJson(ApiEnvelope.unwrapObject(response.data));
  }
}
