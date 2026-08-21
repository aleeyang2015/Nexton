import '../../../../core/errors/exceptions.dart';

/// Body of `POST /auth/login` (`auth.LoginResponse`).
///
/// Parsed by hand rather than generated, because the tokens must be *validated*
/// — a 200 that somehow arrives without them has to fail loudly instead of
/// leaving the app half signed-in.
///
/// `expires_at` (Unix seconds) is on the wire but not modelled: the access
/// token is refreshed reactively on a 401, never pre-emptively by clock.
class LoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final bool mustChangePassword;

  const LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.mustChangePassword,
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
    );
  }
}
