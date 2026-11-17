import '../../domain/entities/ot_piece.dart';
import 'ot_parse.dart';

/// Reads one OT piece (`pieces[]`). Never throws.
class OtPieceModel {
  OtPieceModel._();

  static OtPiece fromJson(Map<String, dynamic> json) => OtPiece(
    id: OtJson.str(json['id']) ?? '',
    pieceNo: OtJson.intOf(json['piece_no']) ?? 0,
    startsAt: OtJson.instant(json['starts_at']),
    endsAt: OtJson.instant(json['ends_at']),
    payType: OtPayType.fromWire(json['pay_type']),
    payValue: OtJson.intOf(json['pay_value']) ?? 0,
  );
}
