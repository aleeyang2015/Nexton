import 'package:equatable/equatable.dart';

/// A work shift a time correction is filed against — e.g. "Standard Shift",
/// split into blocks like 08:00–12:00 and 13:00–17:00.
class WorkShift extends Equatable {
  final String id;

  /// Short code shown in the card's badge, e.g. "Shift A".
  final String code;
  final String name;

  /// Block labels in order, e.g. `['08:00 - 12:00', '13:00 - 17:00']`.
  final List<String> blocks;

  const WorkShift({
    required this.id,
    required this.code,
    required this.name,
    required this.blocks,
  });

  @override
  List<Object?> get props => [id, code, name, blocks];
}
