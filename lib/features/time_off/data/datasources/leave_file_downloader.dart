import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/utils/base_repository.dart';
import '../../../../core/utils/result.dart';

/// Downloads a leave file from its storage URL.
///
/// A plain [Dio], not the App's `ApiClient`: the URL is a public storage
/// link (no token needed), and the App's Bearer header could make the
/// storage refuse it.
class LeaveFileDownloader extends BaseRepository {
  LeaveFileDownloader({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              // A weak signal ends in "can't be opened" with a Retry, not a
              // spinner for ever.
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 60),
            ),
          );

  final Dio _dio;

  FutureResult<Uint8List> download(String url) => guard(() async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('The file came back empty');
    }
    return Uint8List.fromList(bytes);
  });
}
