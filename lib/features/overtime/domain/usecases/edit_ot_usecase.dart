import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/ot_draft.dart';
import '../entities/ot_request.dart';
import '../repositories/ot_repository.dart';

/// The request to change, and what it becomes.
class EditOtParams {
  final String id;
  final OtDraft draft;

  const EditOtParams({required this.id, required this.draft});
}

/// Changes a waiting OT request (`PUT /ot-requests/:id`).
class EditOtUseCase implements BaseUseCase<OtRequest, EditOtParams> {
  final OtRepository _repository;

  EditOtUseCase(this._repository);

  @override
  FutureResult<OtRequest> call(EditOtParams params) =>
      _repository.edit(params.id, params.draft);
}
