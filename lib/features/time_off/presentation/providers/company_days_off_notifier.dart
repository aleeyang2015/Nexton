import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/company_days_off.dart';
import '../../time_off_providers.dart';

/// The company's days off (`GET /core_hr/rest-days`), for the leave form's
/// calendar and its day count.
///
/// A failed load is an error the form shows with a Retry. It never becomes
/// "no days off": that would let the form count days the server will not
/// charge, and offer days it will charge for.
class CompanyDaysOffNotifier extends AutoDisposeAsyncNotifier<CompanyDaysOff> {
  @override
  Future<CompanyDaysOff> build() => _load();

  /// Re-runs the fetch, after the user retries a failed load.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<CompanyDaysOff> _load() async {
    final result = await ref.read(getCompanyDaysOffUseCaseProvider)();
    return result.fold((failure) => throw failure, (daysOff) => daysOff);
  }
}

final companyDaysOffNotifierProvider =
    AsyncNotifierProvider.autoDispose<CompanyDaysOffNotifier, CompanyDaysOff>(
      CompanyDaysOffNotifier.new,
    );
