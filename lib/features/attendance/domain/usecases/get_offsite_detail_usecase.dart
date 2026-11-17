import '../../../../core/utils/result.dart';
import '../entities/offsite_detail.dart';
import '../repositories/offsite_repository.dart';

/// One off-site request by its id, for its detail page (#42).
class GetOffsiteDetailUseCase {
  final OffsiteRepository _repository;

  GetOffsiteDetailUseCase(this._repository);

  FutureResult<OffsiteRequestDetail> call(String id) => _repository.detail(id);
}
