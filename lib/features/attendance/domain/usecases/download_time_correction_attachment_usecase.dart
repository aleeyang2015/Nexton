import 'dart:typed_data';

import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/attendance_repository.dart';

/// Fetches a request's evidence file, by URL, for saving to the device.
class DownloadTimeCorrectionAttachmentUseCase
    implements BaseUseCase<Uint8List, String> {
  final AttendanceRepository _repository;

  DownloadTimeCorrectionAttachmentUseCase(this._repository);

  @override
  FutureResult<Uint8List> call(String url) =>
      _repository.timeCorrectionAttachment(url);
}
