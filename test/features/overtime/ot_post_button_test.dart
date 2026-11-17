import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';
import 'package:next_on/features/overtime/presentation/widgets/ot_post_button.dart';

import '../../support/overtime_test_doubles.dart';

/// The post card's button, by the guide's rule (1.5): never a check of the
/// App's own.
void main() {
  OtPostButton button({
    required bool joinOpen,
    required bool full,
    OtStatus? myJoin,
  }) => OtPostButton.of(
    samplePost(
      'post-1',
      joinOpen: joinOpen,
      full: full,
      myJoin: myJoin == null ? null : sampleOt('ot-j', status: myJoin),
    ),
  );

  test('every combination of join_open, full and my_join', () {
    for (final joinOpen in [true, false]) {
      for (final full in [true, false]) {
        for (final mine in <OtStatus?>[
          null,
          OtStatus.pending,
          OtStatus.approved,
          OtStatus.rejected,
          OtStatus.cancelled,
          OtStatus.unknown,
        ]) {
          final got = button(joinOpen: joinOpen, full: full, myJoin: mine);
          final OtPostButton want;
          if (mine == OtStatus.pending) {
            want = OtPostButton.waiting;
          } else if (mine == OtStatus.approved) {
            want = OtPostButton.accepted;
          } else if (mine == OtStatus.unknown) {
            // A join the App cannot read the state of: never Join again.
            want = OtPostButton.cannotJoin;
          } else if (joinOpen && !full) {
            want = OtPostButton.join;
          } else if (full) {
            want = OtPostButton.full;
          } else {
            want = OtPostButton.cannotJoin;
          }
          expect(got, want, reason: 'open=$joinOpen full=$full mine=$mine');
        }
      }
    }
  });

  test('a rejected or cancelled join may join again; a pending one may not',
      () {
    expect(
      button(joinOpen: true, full: false, myJoin: OtStatus.rejected),
      OtPostButton.join,
    );
    expect(
      button(joinOpen: true, full: false, myJoin: OtStatus.cancelled),
      OtPostButton.join,
    );
    expect(
      button(joinOpen: true, full: false, myJoin: OtStatus.pending),
      OtPostButton.waiting,
    );
  });

  test('a my_join the App could not read: joined, so never Join', () {
    final post = samplePost('post-1', joined: true);

    expect(post.myJoin, isNull);
    expect(OtPostButton.of(post), OtPostButton.cannotJoin);
  });

  test('only Waiting and Accepted open the join', () {
    expect(OtPostButton.waiting.opensJoin, isTrue);
    expect(OtPostButton.accepted.opensJoin, isTrue);
    expect(OtPostButton.join.opensJoin, isFalse);
    expect(OtPostButton.full.opensJoin, isFalse);
    expect(OtPostButton.cannotJoin.opensJoin, isFalse);
  });
}
