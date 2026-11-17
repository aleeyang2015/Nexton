import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/open_ot_session.dart';
import '../repositories/attendance_repository.dart';

/// The user's own open OT clock-in, or null (`GET /ot-sessions/open`).
class GetOpenOtSessionUseCase implements NoParamsUseCase<OpenOtSession?> {
  final AttendanceRepository _repository;

  GetOpenOtSessionUseCase(this._repository);

  @override
  FutureResult<OpenOtSession?> call() => _repository.openOtSession();
}
