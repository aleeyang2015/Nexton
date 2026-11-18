import '../../../../core/utils/result.dart';
import '../../../../core/upload/domain/local_file.dart';
import '../entities/employee_profile.dart';

/// Contract the presentation layer depends on. The implementation lives in
/// data/repositories.
abstract class ProfileRepository {
  /// `GET /core_hr/employees/me` — the signed-in user's own employee record.
  FutureResult<EmployeeProfile> myProfile();

  /// Replaces the employee's own photo (#59): the new photo's URL. A file
  /// over `UploadRules.maxBytes` is refused without being sent.
  FutureResult<String> uploadMyPhoto(String employeeId, LocalFile file);
}
