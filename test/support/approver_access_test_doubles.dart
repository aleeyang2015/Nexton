import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:next_on/features/approvals/domain/approver_access.dart';
import 'package:next_on/features/approvals/presentation/providers/approver_access_provider.dart';
import 'package:next_on/features/auth/domain/entities/auth_session.dart';
import 'package:next_on/features/auth/domain/entities/user.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';

/// A signed-in user for the Approvals place: a department head by default,
/// plain staff with `head: false`.
User approverTestUser({
  bool head = true,
  List<String> roles = const ['employee'],
  List<String> permissions = const [],
  String? employeeId = 'b3f1-employees-uuid',
}) => User(
  id: 'cce14a0e',
  tenantId: 'cbc6553a',
  email: 'somphone.vilaysone@nexton.la',
  firstName: 'Somphone',
  lastName: 'Vilaysone',
  roles: roles,
  permissions: permissions,
  employeeId: employeeId,
  isDepartmentHead: head,
);

/// The Approvals access of [user] (a department head when left out), with
/// no session behind it.
Override approverAccessOf([User? user]) => approverAccessProvider
    .overrideWithValue(ApproverAccess.of(user ?? approverTestUser()));

/// A session signed in as [user], with no repository behind it: for pages
/// that read who is signed in.
Override signedInAs(User user) =>
    authSessionProvider.overrideWith(() => _SignedIn(user));

class _SignedIn extends AuthSessionNotifier {
  _SignedIn(this.user);

  final User user;

  @override
  Future<AuthSession> build() async => AuthSession.signedIn(user);
}
