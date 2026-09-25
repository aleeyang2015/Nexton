import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_providers.dart';
import 'data/datasources/attendance_remote_data_source.dart';
import 'data/datasources/fixed_punch_location_source.dart';
import 'data/datasources/geolocator_punch_location_source.dart';
import 'data/repositories/attendance_repository_impl.dart';
import 'domain/datasources/punch_location_source.dart';
import 'domain/repositories/attendance_repository.dart';
import 'domain/usecases/cancel_time_correction_usecase.dart';
import 'domain/usecases/clock_in_usecase.dart';
import 'domain/usecases/clock_out_usecase.dart';
import 'domain/usecases/download_time_correction_attachment_usecase.dart';
import 'domain/usecases/get_monthly_records_usecase.dart';
import 'domain/usecases/get_monthly_summary_usecase.dart';
import 'domain/usecases/get_time_correction_detail_usecase.dart';
import 'domain/usecases/get_time_correction_history_usecase.dart';
import 'domain/usecases/get_today_attendance_usecase.dart';
import 'domain/usecases/prepare_punch_usecase.dart';
import 'domain/usecases/submit_time_correction_usecase.dart';

/// Composition root for the attendance feature: the one place the data layer
/// is constructed and bound to the domain contracts. Presentation consumes
/// only the use case providers, never the datasources.

/// Reads the device signals a punch carries.
///
/// Backed by geolocator, so a `gps` punch sends a real position, its accuracy
/// and — on Android — the mock-provider verdict. `wifi` punches still have no
/// source for a BSSID and are refused before they are sent.
///
/// In debug builds this is swapped for [FixedPunchLocationSource]: an emulator
/// reports its position as a mock provider, which `PunchRequest.validate`
/// refuses before the punch is sent, making the flow impossible to test on
/// one. Release builds always use the real geolocator source.
final punchLocationSourceProvider = Provider<PunchLocationSource>((ref) {
  if (kDebugMode) return FixedPunchLocationSource.fromEnvironment();
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

final submitTimeCorrectionUseCaseProvider =
    Provider<SubmitTimeCorrectionUseCase>((ref) {
      return SubmitTimeCorrectionUseCase(
        ref.watch(attendanceRepositoryProvider),
      );
    });

final getTimeCorrectionHistoryUseCaseProvider =
    Provider<GetTimeCorrectionHistoryUseCase>((ref) {
      return GetTimeCorrectionHistoryUseCase(
        ref.watch(attendanceRepositoryProvider),
      );
    });

final getTimeCorrectionDetailUseCaseProvider =
    Provider<GetTimeCorrectionDetailUseCase>((ref) {
      return GetTimeCorrectionDetailUseCase(
        ref.watch(attendanceRepositoryProvider),
      );
    });

final cancelTimeCorrectionUseCaseProvider =
    Provider<CancelTimeCorrectionUseCase>((ref) {
      return CancelTimeCorrectionUseCase(
        ref.watch(attendanceRepositoryProvider),
      );
    });

final downloadTimeCorrectionAttachmentUseCaseProvider =
    Provider<DownloadTimeCorrectionAttachmentUseCase>((ref) {
      return DownloadTimeCorrectionAttachmentUseCase(
        ref.watch(attendanceRepositoryProvider),
      );
    });
