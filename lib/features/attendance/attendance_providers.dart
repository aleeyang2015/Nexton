import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_providers.dart';
import 'data/datasources/attendance_remote_data_source.dart';
import 'data/datasources/geolocator_punch_location_source.dart';
import 'data/datasources/offsite_remote_data_source.dart';
import 'data/repositories/attendance_repository_impl.dart';
import 'data/repositories/offsite_repository_impl.dart';
import 'domain/datasources/punch_location_source.dart';
import 'domain/repositories/attendance_repository.dart';
import 'domain/repositories/offsite_repository.dart';
import 'domain/usecases/approve_offsite_request_usecase.dart';
import 'domain/usecases/approve_time_correction_usecase.dart';
import 'domain/usecases/cancel_offsite_request_usecase.dart';
import 'domain/usecases/cancel_time_correction_usecase.dart';
import 'domain/usecases/clock_in_usecase.dart';
import 'domain/usecases/clock_out_usecase.dart';
import 'domain/usecases/download_time_correction_attachment_usecase.dart';
import 'domain/usecases/get_monthly_records_usecase.dart';
import 'domain/usecases/get_offsite_approvals_usecase.dart';
import 'domain/usecases/get_offsite_history_usecase.dart';
import 'domain/usecases/get_monthly_summary_usecase.dart';
import 'domain/usecases/get_time_correction_approvals_usecase.dart';
import 'domain/usecases/get_time_correction_detail_usecase.dart';
import 'domain/usecases/get_time_correction_history_usecase.dart';
import 'domain/usecases/get_today_attendance_usecase.dart';
import 'domain/usecases/prepare_punch_usecase.dart';
import 'domain/usecases/read_offsite_location_usecase.dart';
import 'domain/usecases/reject_offsite_request_usecase.dart';
import 'domain/usecases/reject_time_correction_usecase.dart';
import 'domain/usecases/submit_offsite_request_usecase.dart';
import 'domain/usecases/submit_time_correction_usecase.dart';

/// Composition root for the attendance feature: the one place the data layer
/// is constructed and bound to the domain contracts. Presentation consumes
/// only the use case providers, never the datasources.

/// Reads the device signals a punch carries.
///
/// Backed by geolocator in every build, so a `gps` punch sends the device's
/// own current position, its accuracy and — on Android — the mock-provider
/// verdict. `wifi` punches still have no source for a BSSID and are refused
/// before they are sent.
///
/// No build substitutes a fixed coordinate: a punch reports where the device
/// actually is, or it reports nothing and `PunchRequest.validate` explains
/// why. The consequence is that an emulator cannot clock in — it reports its
/// position as a mock provider, which validation refuses — so the flow is
/// exercised on a real device.
final punchLocationSourceProvider = Provider<PunchLocationSource>(
  (ref) => GeolocatorPunchLocationSource(),
);

final attendanceRemoteDataSourceProvider = Provider<AttendanceRemoteDataSource>(
  (ref) => AttendanceRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

/// Exposed as the abstract type so consumers never see the impl.
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepositoryImpl(
    remote: ref.watch(attendanceRemoteDataSourceProvider),
  );
});

final offsiteRemoteDataSourceProvider = Provider<OffsiteRemoteDataSource>(
  (ref) => OffsiteRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

/// The off-site scan requests, bound separately from
/// [attendanceRepositoryProvider] — see [OffsiteRepository] for why the two
/// contracts stay apart.
final offsiteRepositoryProvider = Provider<OffsiteRepository>((ref) {
  return OffsiteRepositoryImpl(
    remote: ref.watch(offsiteRemoteDataSourceProvider),
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

final getTimeCorrectionApprovalsUseCaseProvider =
    Provider<GetTimeCorrectionApprovalsUseCase>((ref) {
      return GetTimeCorrectionApprovalsUseCase(
        ref.watch(attendanceRepositoryProvider),
      );
    });

final approveTimeCorrectionUseCaseProvider =
    Provider<ApproveTimeCorrectionUseCase>((ref) {
      return ApproveTimeCorrectionUseCase(
        ref.watch(attendanceRepositoryProvider),
      );
    });

final rejectTimeCorrectionUseCaseProvider =
    Provider<RejectTimeCorrectionUseCase>((ref) {
      return RejectTimeCorrectionUseCase(
        ref.watch(attendanceRepositoryProvider),
      );
    });

final submitOffsiteRequestUseCaseProvider =
    Provider<SubmitOffsiteRequestUseCase>((ref) {
      return SubmitOffsiteRequestUseCase(ref.watch(offsiteRepositoryProvider));
    });

/// Reads the position an off-site scan is filed from, through the same source
/// a GPS punch uses.
final readOffsiteLocationUseCaseProvider = Provider<ReadOffsiteLocationUseCase>(
  (ref) => ReadOffsiteLocationUseCase(ref.watch(punchLocationSourceProvider)),
);

/// The employee's own off-site requests, for the history page in front of the
/// request form.
final getOffsiteHistoryUseCaseProvider = Provider<GetOffsiteHistoryUseCase>(
  (ref) => GetOffsiteHistoryUseCase(ref.watch(offsiteRepositoryProvider)),
);

final getOffsiteApprovalsUseCaseProvider = Provider<GetOffsiteApprovalsUseCase>(
  (ref) => GetOffsiteApprovalsUseCase(ref.watch(offsiteRepositoryProvider)),
);

final approveOffsiteRequestUseCaseProvider =
    Provider<ApproveOffsiteRequestUseCase>((ref) {
      return ApproveOffsiteRequestUseCase(ref.watch(offsiteRepositoryProvider));
    });

/// The employee withdrawing their own pending request, from the history page.
final cancelOffsiteRequestUseCaseProvider =
    Provider<CancelOffsiteRequestUseCase>((ref) {
      return CancelOffsiteRequestUseCase(ref.watch(offsiteRepositoryProvider));
    });

final rejectOffsiteRequestUseCaseProvider =
    Provider<RejectOffsiteRequestUseCase>((ref) {
      return RejectOffsiteRequestUseCase(ref.watch(offsiteRepositoryProvider));
    });
