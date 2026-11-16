import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/token_storage.dart';

/// Body of `POST /auth/login` (`auth.LoginResponse`).
///
/// Parsed by hand rather than generated, because the tokens must be *validated*
/// — a 200 that somehow arrives without them has to fail loudly instead of
/// leaving the app half signed-in.
///
/// `expires_at` (Unix seconds) is modelled and persisted with the tokens, but
/// it does **not** drive refreshing: the access token is still refreshed
/// reactively on a 401, never pre-emptively by clock (auth-login.md §5).
class LoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final bool mustChangePassword;

  /// When [accessToken] expires, or null when the response carried no usable
  /// `expires_at`. An unknown expiry is not an expired one.
  final DateTime? expiresAt;

  const LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.mustChangePassword,
    this.expiresAt,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final accessToken = json['access_token'];
    final refreshToken = json['refresh_token'];

    if (accessToken is! String || refreshToken is! String) {
      throw const ServerException('Login response missing tokens');
    }

    return LoginResponseModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      mustChangePassword: json['must_change_password'] == true,
      expiresAt: tokenExpiryFromUnixSeconds(json['expires_at']),
    );
  }

  /// True once [expiresAt] has passed. An unknown expiry reads as *not*
  /// expired — the 401 handling is what actually establishes that a token is
  /// dead, and guessing here would sign a working session out.
  bool get isExpired {
    final expiry = expiresAt;
    return expiry != null && !DateTime.now().toUtc().isBefore(expiry);
  }
}
