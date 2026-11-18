import 'dart:async';

import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/profile/domain/entities/employee_profile.dart';
import 'package:next_on/features/profile/domain/repositories/profile_repository.dart';
import 'package:next_on/core/upload/domain/local_file.dart';

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

  /// When set, the profile waits for it: still loading.
  Completer<void>? hold;

  @override
  FutureResult<EmployeeProfile> myProfile() async {
    calls++;
    await hold?.future;
    return profile;
  }

  /// The photo change (#59): what it answers, each one asked for, and an
  /// answer that can be held.
  Result<String> photoResult = const Result.success(
    'https://files.nexton.work/photos/new.jpg',
  );
  final List<({String employeeId, LocalFile file})> photoUploads = [];
  Completer<void>? holdPhoto;

  @override
  FutureResult<String> uploadMyPhoto(String employeeId, LocalFile file) async {
    photoUploads.add((employeeId: employeeId, file: file));
    await holdPhoto?.future;
    return photoResult;
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
