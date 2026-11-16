import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/offsite_repository.dart';

/// Rejects a pending off-site scan request. [note] is required — it is what the
/// employee sees on their request. [stepId] guards against the step having
/// moved on, as on [ApproveOffsiteRequestUseCase].
class RejectOffsiteRequestUseCase
    implements BaseUseCase<Unit, ({String id, String note, String? stepId})> {
  final OffsiteRepository _repository;

  RejectOffsiteRequestUseCase(this._repository);

  @override
  FutureResult<Unit> call(({String id, String note, String? stepId}) p) =>
      _repository.reject(p.id, note: p.note, stepId: p.stepId);
}
