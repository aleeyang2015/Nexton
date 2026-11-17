import 'package:equatable/equatable.dart';

/// One page of an OT list. The OT lists are page-based (`meta {page,
/// per_page, total, total_pages}`), not cursor-based like the leave lists.
class OtPage<T> extends Equatable {
  final List<T> items;

  /// This page's number, from 1.
  final int page;
  final int totalPages;

  const OtPage({required this.items, required this.page, required this.totalPages});

  /// True when there is a page after this one.
  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, totalPages];
}
