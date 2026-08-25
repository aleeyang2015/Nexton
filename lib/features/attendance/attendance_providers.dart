import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_providers.dart';
import 'data/datasources/attendance_remote_data_source.dart';
import 'data/datasources/geolocator_punch_location_source.dart';
import 'data/repositories/attendance_repository_impl.dart';
import 'domain/datasources/punch_location_source.dart';
import 'domain/repositories/attendance_repository.dart';
import 'domain/usecases/clock_in_usecase.dart';
import 'domain/usecases/clock_out_usecase.dart';
import 'domain/usecases/get_monthly_records_usecase.dart';
import 'domain/usecases/get_monthly_summary_usecase.dart';
import 'domain/usecases/get_today_attendance_usecase.dart';
import 'domain/usecases/prepare_punch_usecase.dart';

/// Composition root for the attendance feature: the one place the data layer
/// is constructed and bound to the domain contracts. Presentation consumes
/// only the use case providers, never the datasources.

/// Reads the device signals a punch carries.
///
/// Backed by geolocator, so a `gps` punch sends a real position, its accuracy
/// and — on Android — the mock-provider verdict. `wifi` punches still have no
/// source for a BSSID and are refused before they are sent.
final punchLocationSourceProvider = Provider<PunchLocationSource>((ref) {
  return GeolocatorPunchLocationSource();
});

final attendanceRemoteDataSourceProvider = Provider<AttendanceRemoteDataSource>(
  (ref) => AttendanceRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

/// Exposed as the abstract type so consumers never see the impl.
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepositoryImpl(
    remote: ref.watch(attendanceRemoteDataSourceProvider),
  );
});

final preparePunchUseCaseProvider = Provider<PreparePunchUseCase>((ref) {
  return PreparePunchUseCase(ref.watch(punchLocationSourceProvider));
});

final clockInUseCaseProvider = Provider<ClockInUseCase>((ref) {
  return ClockInUseCase(ref.watch(attendanceRepositoryProvider));
});

final clockOutUseCaseProvider = Provider<ClockOutUseCase>((ref) {
  return ClockOutUseCase(ref.watch(attendanceRepositoryProvider));
});

final getTodayAttendanceUseCaseProvider = Provider<GetTodayAttendanceUseCase>((
  ref,
) {
  return GetTodayAttendanceUseCase(ref.watch(attendanceRepositoryProvider));
});

final getMonthlyRecordsUseCaseProvider = Provider<GetMonthlyRecordsUseCase>((
  ref,
) {
  return GetMonthlyRecordsUseCase(ref.watch(attendanceRepositoryProvider));
});

final getMonthlySummaryUseCaseProvider = Provider<GetMonthlySummaryUseCase>((
  ref,
) {
  return GetMonthlySummaryUseCase(ref.watch(attendanceRepositoryProvider));
});
