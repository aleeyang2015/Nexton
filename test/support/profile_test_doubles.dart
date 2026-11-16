import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/profile/domain/entities/employee_profile.dart';
import 'package:next_on/features/profile/domain/repositories/profile_repository.dart';

/// Repository stand-in for the profile widgets: answers [profile] and counts
/// how often it was asked.
class FakeProfileRepository implements ProfileRepository {
  Result<EmployeeProfile> profile = const Result.success(
    EmployeeProfile(
      id: 'emp-1',
      fullName: 'Somphone Vilaysone',
      email: 'somphone.vilaysone@nexton.la',
      positionTitle: 'Cashier',
    ),
  );

  int calls = 0;

  @override
  FutureResult<EmployeeProfile> myProfile() async {
    calls++;
    return profile;
  }
}

/// Profiles reused across the widget tests.
class EmployeeProfileStub {
  const EmployeeProfileStub._();

  static const somphone = EmployeeProfile(
    id: 'emp-1',
    fullName: 'Somphone Vilaysone',
    email: 'somphone.vilaysone@nexton.la',
    positionTitle: 'Cashier',
  );
}
