import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/ot_request.dart';
import '../repositories/ot_repository.dart';

/// Joins an HR OT post (`POST /ot-announcements/:id/join`).
class JoinOtPostUseCase implements BaseUseCase<OtRequest, String> {
  final OtRepository _repository;

  JoinOtPostUseCase(this._repository);

  @override
  FutureResult<OtRequest> call(String postId) => _repository.join(postId);
}
