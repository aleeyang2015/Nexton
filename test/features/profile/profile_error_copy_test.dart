import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/features/profile/presentation/profile_error_copy.dart';
import 'package:next_on/l10n/generated/app_localizations.dart';

void main() {
  final lo = lookupAppLocalizations(const Locale('lo'));
  final en = lookupAppLocalizations(const Locale('en'));

  const couldNotLoadLo = 'ບໍ່ສາມາດໂຫຼດໂປຣຟາຍໄດ້.';
  const couldNotLoadEn = 'Could not load your profile.';

  group('the rows of the table', () {
    test('400 EMPLOYEE_NOT_FOUND: the not-linked text, no Retry', () {
      const failure = Failure.validation(
        message: 'employee not found',
        code: 'EMPLOYEE_NOT_FOUND',
      );

      final copy = profileErrorCopy(lo, failure);

      expect(
        copy.text,
        'ບັນຊີຂອງທ່ານຍັງບໍ່ໄດ້ຜູກກັບຂໍ້ມູນພະນັກງານ. ກະລຸນາຕິດຕໍ່ HR.',
      );
      expect(copy.canRetry, isFalse);
      expect(
        profileErrorCopy(en, failure).text,
        'Your account is not linked to an employee record. '
        'Please contact HR.',
      );
    });

    test('403 MODULE_NOT_ACTIVE: its own text, no Retry', () {
      const failure = Failure.validation(
        message: "Module 'core_hr' is not active for this subscription",
        code: 'MODULE_NOT_ACTIVE',
      );

      final copy = profileErrorCopy(lo, failure);

      expect(copy.text, lo.errorModuleNotActive);
      expect(copy.canRetry, isFalse);
    });

    test('503 TENANT_UNAVAILABLE: its own text, with Retry', () {
      const failure = Failure.server(
        message: 'tenant database unavailable',
        statusCode: 503,
        errorCode: 'TENANT_UNAVAILABLE',
      );

      final copy = profileErrorCopy(lo, failure);

      expect(copy.text, lo.errorTenantUnavailable);
      expect(copy.canRetry, isTrue);
    });

    test('a 500 is "could not load your profile", with Retry: a database '
        'fault is never "not linked"', () {
      const failure = Failure.server(
        message: 'boom',
        statusCode: 500,
        errorCode: 'INTERNAL_ERROR',
      );

      expect(profileErrorCopy(lo, failure), (
        text: couldNotLoadLo,
        canRetry: true,
      ));
      expect(profileErrorCopy(en, failure).text, couldNotLoadEn);
    });

    test('no connection and a timeout are "could not load", with Retry', () {
      for (final failure in const [
        Failure.network(message: 'No internet connection', errorCode: 'NO_INTERNET'),
        Failure.network(message: 'Request timeout', errorCode: 'TIMEOUT'),
      ]) {
        expect(profileErrorCopy(lo, failure), (
          text: couldNotLoadLo,
          canRetry: true,
        ), reason: '$failure');
      }
    });
  });

  group('everything else', () {
    test('another 5xx, with or without a code, is "could not load" with '
        'Retry', () {
      for (final failure in const [
        Failure.server(message: 'bad gateway', statusCode: 502),
        Failure.server(
          message: 'odd',
          statusCode: 503,
          errorCode: 'SOMETHING_NEW',
        ),
      ]) {
        expect(profileErrorCopy(en, failure), (
          text: couldNotLoadEn,
          canRetry: true,
        ));
      }
    });

    test('503 TENANT_LOOKUP_FAILED shares the company-not-ready text', () {
      const failure = Failure.server(
        message: 'lookup failed',
        statusCode: 503,
        errorCode: 'TENANT_LOOKUP_FAILED',
      );

      expect(profileErrorCopy(lo, failure), (
        text: lo.errorTenantUnavailable,
        canRetry: true,
      ));
    });

    test('a refusal with a code the App does not know shows the server\'s '
        'message, and no Retry', () {
      const failure = Failure.validation(
        message: 'Profile is locked',
        code: 'PROFILE_LOCKED',
      );

      expect(profileErrorCopy(lo, failure), (
        text: 'Profile is locked',
        canRetry: false,
      ));
    });

    test('a 4xx with no narrower kind is a verdict: no Retry', () {
      const failure = Failure.network(
        message: 'Tenant subdomain is not registered',
        statusCode: 404,
        errorCode: 'TENANT_NOT_FOUND',
      );

      final copy = profileErrorCopy(lo, failure);

      expect(copy.text, lo.errorTenantNotFound);
      expect(copy.canRetry, isFalse);
    });

    test('a lost session offers no Retry', () {
      const failure = Failure.auth(message: 'expired', code: 'INVALID_TOKEN');

      expect(profileErrorCopy(lo, failure).canRetry, isFalse);
    });

    test('an unreadable answer or a non-Failure error is "could not load" '
        'with Retry', () {
      expect(
        profileErrorCopy(en, const Failure.unknown(message: 'bad json')),
        (text: couldNotLoadEn, canRetry: true),
      );
      expect(profileErrorCopy(en, StateError('odd')), (
        text: couldNotLoadEn,
        canRetry: true,
      ));
    });
  });
}
