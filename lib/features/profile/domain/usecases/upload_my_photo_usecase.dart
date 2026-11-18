import '../../../../core/upload/domain/local_file.dart';
import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/profile_repository.dart';

/// The employee and the photo to put on their record.
typedef MyPhoto = ({String employeeId, LocalFile file});

/// Replaces the employee's own photo (#59): the new photo's URL.
class UploadMyPhotoUseCase implements BaseUseCase<String, MyPhoto> {
  final ProfileRepository _repository;

  UploadMyPhotoUseCase(this._repository);

  @override
  FutureResult<String> call(MyPhoto photo) =>
      _repository.uploadMyPhoto(photo.employeeId, photo.file);
}
