import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/ot_draft.dart';
import '../entities/ot_request.dart';
import '../repositories/ot_repository.dart';

/// Asks for OT (`POST /ot-requests`).
class AskOtUseCase implements BaseUseCase<OtRequest, OtDraft> {
  final OtRepository _repository;

  AskOtUseCase(this._repository);

  @override
  FutureResult<OtRequest> call(OtDraft draft) => _repository.ask(draft);
}
