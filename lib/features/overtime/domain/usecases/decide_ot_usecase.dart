import '../../../../core/utils/result.dart';
import '../entities/ot_request.dart';
import '../repositories/ot_repository.dart';

/// A head's decision on the OT request waiting at their step (#49): approve
/// with an optional comment, or reject with a reason. Answers the request
/// as it now is.
class DecideOtUseCase {
  final OtRepository _repository;

  DecideOtUseCase(this._repository);

  FutureResult<OtRequest> approve(
    String id, {
    required String stepId,
    String? comment,
  }) => _repository.approve(id, stepId: stepId, comment: comment);

  FutureResult<OtRequest> reject(
    String id, {
    required String stepId,
    required String comment,
  }) => _repository.reject(id, stepId: stepId, comment: comment);
}
