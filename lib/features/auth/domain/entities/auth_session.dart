import 'package:equatable/equatable.dart';

import '../../../../core/network/session_end_reason.dart';
import 'user.dart';

/// The session state machine from auth.md. Which shell the app shows is a
/// function of this value and nothing else.
enum AuthStatus {
  /// Cold start; the stored session has not been resolved yet.
  bootstrapping,

  /// No valid session — the login screen owns the app.
  unauthenticated,

  /// Full session.
  authenticated,

  /// Signed in, but the backend flagged the password as needing a change
  /// before the user may go anywhere else.
  mustChangePassword,
}

/// Status plus the profile that belongs to it.
class AuthSession extends Equatable {
  final AuthStatus status;
  final User? user;

  /// Why the App ended the last session, when it was not the user's choice.
  /// Only ever set on an unauthenticated session; the sign-in screen says it
  /// once and clears it.
  final SessionEndReason? endReason;

  const AuthSession({required this.status, this.user, this.endReason});

  const AuthSession.bootstrapping()
    : status = AuthStatus.bootstrapping,
      user = null,
      endReason = null;

  const AuthSession.unauthenticated({this.endReason})
    : status = AuthStatus.unauthenticated,
      user = null;

  /// [mustChangePassword] comes from the login response only — `/auth/me`
  /// never reports it.
  const AuthSession.signedIn(User this.user, {bool mustChangePassword = false})
    : status = mustChangePassword
          ? AuthStatus.mustChangePassword
          : AuthStatus.authenticated,
      endReason = null;

  /// True once tokens are valid, whether or not a password change is pending.
  bool get hasSession =>
      status == AuthStatus.authenticated ||
      status == AuthStatus.mustChangePassword;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get mustChangePassword => status == AuthStatus.mustChangePassword;

  AuthSession copyWith({AuthStatus? status, User? user}) =>
      AuthSession(status: status ?? this.status, user: user ?? this.user);

  @override
  List<Object?> get props => [status, user, endReason];
}
