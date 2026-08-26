import 'package:equatable/equatable.dart';

import 'leave_category.dart';

/// One category's entitlement/used/remaining rollup for the annual summary
/// tab.
class LeaveCategoryBalance extends Equatable {
  final LeaveCategory category;
  final int entitledDays;
  final int usedDays;

  const LeaveCategoryBalance({
    required this.category,
    required this.entitledDays,
    required this.usedDays,
  });

  int get remainingDays => entitledDays - usedDays;

  @override
  List<Object?> get props => [category, entitledDays, usedDays];
}

class LeaveSummary extends Equatable {
  final int year;
  final List<LeaveCategoryBalance> balances;

  const LeaveSummary({required this.year, required this.balances});

  @override
  List<Object?> get props => [year, balances];
}
