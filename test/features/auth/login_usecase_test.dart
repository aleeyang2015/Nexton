import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/auth/domain/entities/auth_session.dart';
import 'package:next_on/features/auth/domain/usecases/login_usecase.dart';

import '../../support/auth_test_doubles.dart';

void main() {
  late FakeAuthRepository repository;
  late LoginUseCase login;

  setUp(() {
    repository = FakeAuthRepository()
      ..loginResult = Result.success(AuthSession.signedIn(testUser()));
    login = LoginUseCase(repository);
  });

  tearDown(() => repository.sessionExpired.close());

  test('the email reaches the repository as typed, trimmed only', () async {
    await login(LoginParams(email: '  Somchai@Shop.la ', password: 'password1'));

    // HR saved it with capitals; the App must not decide otherwise.
    expect(repository.lastLoginEmail, 'Somchai@Shop.la');
    expect(repository.lastLoginPassword, 'password1');
  });

  test('the password is sent untouched', () async {
    await login(LoginParams(email: 'a@b.la', password: '  Pass word1 '));

    expect(repository.lastLoginPassword, '  Pass word1 ');
  });

  test('an invalid email never reaches the repository', () async {
    final result = await login(
      LoginParams(email: 'not-an-email', password: 'password1'),
    );

    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(repository.loginCalls, 0);
  });
}
