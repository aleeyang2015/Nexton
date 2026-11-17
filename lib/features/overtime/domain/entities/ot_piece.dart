import 'package:equatable/equatable.dart';

import '../../../../core/utils/ot_pay_type.dart';

export '../../../../core/utils/ot_pay_type.dart' show OtPayType;

/// One piece of an OT, with its own pay (`pieces[]`). HR's approval cuts an
/// OT into pieces by pay rate; a request has none until then.
class OtPiece extends Equatable {
  final String id;
  final int pieceNo;

  /// The piece's window, on the phone's clock.
  final DateTime? startsAt;
  final DateTime? endsAt;

  final OtPayType payType;

  /// A whole percent of the hourly pay (150), or whole kip per hour (20000),
  /// by [payType].
  final int payValue;

  const OtPiece({
    required this.id,
    required this.pieceNo,
    this.startsAt,
    this.endsAt,
    required this.payType,
    required this.payValue,
  });

  @override
  List<Object?> get props => [id, pieceNo, startsAt, endsAt, payType, payValue];
}
