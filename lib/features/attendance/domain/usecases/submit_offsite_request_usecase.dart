import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/offsite_outcome.dart';
import '../entities/offsite_request.dart';
import '../repositories/offsite_repository.dart';

/// Files an off-site scan request (`POST /attendance/offsite-requests`).
///
/// Re-validates even though the form already did: this is the one gate every
/// request passes through before it reaches the network.
class SubmitOffsiteRequestUseCase
    implements BaseUseCase<OffsiteOutcome, OffsiteRequest> {
  final OffsiteRepository _repository;

  SubmitOffsiteRequestUseCase(this._repository);

  @override
  FutureResult<OffsiteOutcome> call(OffsiteRequest params) async {
    final validation = params.validate();
    if (validation.isFailure) {
      return Result.failure(validation.failureOrNull!);
    }

    return _repository.submit(params);
  }
}
