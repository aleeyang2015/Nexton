import '../../../../core/utils/result.dart';
import '../entities/offsite_detail.dart';
import '../repositories/offsite_repository.dart';

/// The caller's off-site scans still waiting for a decision that the card
/// must know about (#41): those scanned this month, and on the 1st also last
/// month (a night shift's check-in from the evening before). The two months
/// are asked for together.
class GetWaitingOffsiteUseCase {
  const GetWaitingOffsiteUseCase(this._repository);

  final OffsiteRepository _repository;

  FutureResult<List<OffsiteRequestDetail>> call(DateTime today) async {
    final months = [
      _month(today),
      if (today.day == 1) _month(DateTime(today.year, today.month - 1)),
    ];
    final results = await Future.wait([
      for (final month in months) _repository.waiting(month: month),
    ]);
    final waiting = <OffsiteRequestDetail>[];
    for (final result in results) {
      final failure = result.failureOrNull;
      if (failure != null) return Result.failure(failure);
      waiting.addAll(result.dataOrNull!);
    }
    return Result.success(waiting);
  }

  static String _month(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';
}
