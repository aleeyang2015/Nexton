import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../../domain/approver_access.dart';

/// What the signed-in user may see of the Approvals place. Follows the
/// session: a sign-out, or `/auth/me` read again on resume, changes it.
///
/// AutoDispose, and rebuilt only when the user changes, so a session that
/// changes hands never keeps the last user's access.
final approverAccessProvider = Provider.autoDispose<ApproverAccess>(
  (ref) => ApproverAccess.of(
    ref.watch(authSessionProvider.select((s) => s.valueOrNull?.user)),
  ),
);
