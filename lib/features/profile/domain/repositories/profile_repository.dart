import '../../../../core/utils/result.dart';
import '../entities/employee_profile.dart';

/// Contract the presentation layer depends on. The implementation lives in
/// data/repositories.
abstract class ProfileRepository {
  /// `GET /core_hr/employees/me` — the signed-in user's own employee record.
  FutureResult<EmployeeProfile> myProfile();
}
