import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/ot_page.dart';
import '../entities/ot_request.dart';
import '../repositories/ot_repository.dart';

/// Which of the caller's OT requests to load: a status (null is all), a
/// month (null is every month) and the page.
class MyOtRequestsQuery {
  final OtStatus? status;
  final DateTime? month;
  final int page;
  final int perPage;

  const MyOtRequestsQuery({
    this.status,
    this.month,
    this.page = 1,
    this.perPage = 20,
  });
}

/// The caller's OT requests, one page (`GET /ot-requests/my`).
class GetMyOtRequestsUseCase
    implements BaseUseCase<OtPage<OtRequest>, MyOtRequestsQuery> {
  final OtRepository _repository;

  GetMyOtRequestsUseCase(this._repository);

  @override
  FutureResult<OtPage<OtRequest>> call(MyOtRequestsQuery query) =>
      _repository.myRequests(
        status: query.status,
        month: query.month,
        page: query.page,
        perPage: query.perPage,
      );
}
