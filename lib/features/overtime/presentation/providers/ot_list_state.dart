import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paged_list.dart';
import '../../domain/entities/ot_request.dart';

/// What the OT list shows: the two filters and the requests loaded so far.
///
/// [status] null is every status; [month] null is every month, else the
/// first day of the month shown.
class OtListState {
  final OtStatus? status;
  final DateTime? month;
  final AsyncValue<PagedList<OtRequest>> requests;

  const OtListState({
    this.status,
    this.month,
    this.requests = const AsyncValue.loading(),
  });

  /// The same filters with other [requests].
  OtListState withRequests(AsyncValue<PagedList<OtRequest>> requests) =>
      OtListState(status: status, month: month, requests: requests);

  /// New filters, the list loading from its first page.
  OtListState withFilters({OtStatus? status, DateTime? month}) =>
      OtListState(status: status, month: month);
}
