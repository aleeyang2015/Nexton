import '../../domain/entities/ot_post.dart';
import '../../domain/entities/ot_request.dart';

/// What the post card's button is, by the guide's rule (1.5). The App adds
/// no check of its own: `join_open` and `full` are the server's answers.
enum OtPostButton {
  /// ເຂົ້າຮ່ວມ: open to joining, a place left, and no join of the user's
  /// own that still counts (none, or one rejected or cancelled).
  join,

  /// ລໍຖ້າຝ່າຍບຸກຄະລາກອນ: the user's join waits for HR.
  waiting,

  /// ຮັບແລ້ວ: the user's join was accepted.
  accepted,

  /// ເຕັມແລ້ວ: every place is taken.
  full,

  /// ເຂົ້າຮ່ວມບໍ່ໄດ້ຕອນນີ້: closed to joining (OT off, the user's own OT
  /// switch off, or past the deadline: the App cannot tell which), or a
  /// join the App cannot read the state of.
  cannotJoin;

  /// True for the states that open the user's join (its request page).
  bool get opensJoin => this == waiting || this == accepted;

  static OtPostButton of(OtPost post) {
    final mine = post.myJoin;
    // Joined, but what was sent could not be read: never offer Join again.
    if (post.joined && mine == null) return cannotJoin;
    switch (mine?.status) {
      case OtStatus.pending:
        return waiting;
      case OtStatus.approved:
        return accepted;
      case OtStatus.unknown:
        return cannotJoin;
      case OtStatus.rejected || OtStatus.cancelled || null:
        if (post.joinOpen && !post.full) return join;
        return post.full ? full : cannotJoin;
    }
  }
}
