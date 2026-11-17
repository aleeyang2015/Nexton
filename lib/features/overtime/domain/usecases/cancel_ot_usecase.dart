import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/ot_request.dart';
import '../repositories/ot_repository.dart';

/// Cancels an OT request (`PUT /ot-requests/:id/cancel`).
class CancelOtUseCase implements BaseUseCase<OtRequest, String> {
  final OtRepository _repository;

  CancelOtUseCase(this._repository);

  @override
  FutureResult<OtRequest> call(String id) => _repository.cancel(id);
}
