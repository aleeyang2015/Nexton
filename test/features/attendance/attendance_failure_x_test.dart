import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/features/attendance/domain/attendance_failure_x.dart';

void main() {
  group('isRetryable: only when the request never reached a verdict', () {
    test('a timeout is retryable', () {
      const failure = Failure.network(
        message: 'Request timeout. Please try again.',
        errorCode: 'TIMEOUT',
      );

      expect(failure.isRetryable, isTrue);
    });

    test('no connection is retryable', () {
      const failure = Failure.network(
        message: 'No internet connection',
        errorCode: 'NO_INTERNET',
      );

      expect(failure.isRetryable, isTrue);
    });

    test('a 500 is retryable', () {
      const failure = Failure.server(
        message: 'boom',
        statusCode: 500,
        errorCode: 'INTERNAL_ERROR',
      );

      expect(failure.isRetryable, isTrue);
    });

    test('a 409 is a verdict: the same punch gets the same refusal', () {
      const failure = Failure.network(
        message: 'Shift is locked for payroll',
        statusCode: 409,
        errorCode: 'SHIFT_LOCKED',
      );

      expect(failure.isRetryable, isFalse);
    });

    test('a 404 is not retryable', () {
      const failure = Failure.network(
        message: 'Resource not found.',
        statusCode: 404,
        errorCode: 'NOT_FOUND',
      );

      expect(failure.isRetryable, isFalse);
    });

    test('a 429 is not retryable: the cooldown is there to stop another try',
        () {
      const failure = Failure.network(
        message: 'Too many requests',
        statusCode: 429,
        errorCode: 'RATE_LIMITED',
      );

      expect(failure.isRetryable, isFalse);
      expect(failure.isThrottled, isTrue);
    });

    test('a refusal (400/403) and a lost session are not retryable', () {
      expect(
        const Failure.validation(
          message: 'not bought',
          code: 'MODULE_NOT_ACTIVE',
        ).isRetryable,
        isFalse,
      );
      expect(
        const Failure.auth(message: 'expired', code: 'INVALID_TOKEN').isRetryable,
        isFalse,
      );
    });
  });
}
