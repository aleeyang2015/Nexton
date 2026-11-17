import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/ot_request.dart';
import '../repositories/ot_repository.dart';

/// One OT request, by its id (`GET /ot-requests/:id`).
class GetOtRequestUseCase implements BaseUseCase<OtRequest, String> {
  final OtRepository _repository;

  GetOtRequestUseCase(this._repository);

  @override
  FutureResult<OtRequest> call(String id) => _repository.request(id);
}
