import '../../../../core/utils/base_usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/ot_page.dart';
import '../entities/ot_post.dart';
import '../repositories/ot_repository.dart';

/// HR's open OT posts for the caller's department, one page
/// (`GET /ot-announcements/open`). The parameter is the page number.
class GetOpenOtPostsUseCase implements BaseUseCase<OtPage<OtPost>, int> {
  final OtRepository _repository;

  GetOpenOtPostsUseCase(this._repository);

  @override
  FutureResult<OtPage<OtPost>> call(int page) =>
      _repository.openPosts(page: page);
}
