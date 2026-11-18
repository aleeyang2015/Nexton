import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/network/session_end_reason.dart';
import 'package:next_on/core/network/token_storage.dart';
import 'package:next_on/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:next_on/features/auth/data/models/login_response_model.dart';
import 'package:next_on/features/auth/data/models/user_model.dart';
import 'package:next_on/features/auth/data/repositories/auth_repository_impl.dart';

import '../../support/auth_test_doubles.dart';

/// Whether the signed-in user heads a department (`is_department_head`):
/// what the Approvals place hangs on. `/auth/me` sends it fresh on every
/// call (live since 14 Nov); the login answer sends it too.
void main() {
  group('reading it', () {
    Map<String, dynamic> tokens([Object? flag]) => {
      'access_token': 'a',
      'refresh_token': 'r',
      if (flag != null) 'is_department_head': flag,
    };

    test('the login answer: true is true; missing or anything else is false',
        () {
      expect(LoginResponseModel.fromJson(tokens(true)).isDepartmentHead, isTrue);
      expect(LoginResponseModel.fromJson(tokens()).isDepartmentHead, isFalse);
      expect(
        LoginResponseModel.fromJson(tokens('true')).isDepartmentHead,
        isFalse,
      );
    });

    Map<String, dynamic> me([Object? flag]) => {
      'id': 'u1',
      'tenant_id': 't1',
      'email': 'a@b.la',
      'first_name': 'A',
      'last_name': 'B',
      if (flag != null) 'is_department_head': flag,
    };

    test('/auth/me: true and false as sent; missing is "not said" (null)', () {
      expect(UserModel.fromJson(me(true)).isDepartmentHead, isTrue);
      expect(UserModel.fromJson(me(false)).isDepartmentHead, isFalse);
      expect(UserModel.fromJson(me()).isDepartmentHead, isNull);
    });

    test('/auth/me sending it as another type is "not said", never a failed '
        'sign-in', () {
      expect(UserModel.fromJson(me('true')).isDepartmentHead, isNull);
      expect(UserModel.fromJson(me(1)).isDepartmentHead, isNull);
    });

    test('the user is a head only when it was said so', () {
      expect(UserModel.fromJson(me(true)).toEntity().isDepartmentHead, isTrue);
      expect(UserModel.fromJson(me()).toEntity().isDepartmentHead, isFalse);
    });

    test('headed_department_ids (#50): read as sent, kept through the cache '
        'and onto the user; anything else is none', () {
      final json = {
        ...me(true),
        'headed_department_ids': ['d-sales', 'd-kitchen'],
      };
      final model = UserModel.fromJson(json);
      expect(model.toEntity().headedDepartmentIds, ['d-sales', 'd-kitchen']);
      expect(
        UserModel.fromJson(model.toJson()).headedDepartmentIds,
        ['d-sales', 'd-kitchen'],
      );
      expect(
        model.withDepartmentHead(true).headedDepartmentIds,
        ['d-sales', 'd-kitchen'],
      );
      expect(UserModel.fromJson(me(true)).headedDepartmentIds, isEmpty);
      expect(
        UserModel.fromJson({
          ...me(true),
          'headed_department_ids': ['d-1', 2, '', null],
        }).headedDepartmentIds,
        ['d-1'],
      );
      expect(
        UserModel.fromJson({...me(true), 'headed_department_ids': 'd-1'})
            .headedDepartmentIds,
        isEmpty,
      );
    });

    test('it survives the cache (toJson / fromJson)', () {
      final cached = UserModel.fromJson(
        UserModel.fromJson(me(true)).toJson(),
      );
      expect(cached.isDepartmentHead, isTrue);
    });
  });

  group('the session', () {
    late FakeAuthRemoteDataSource remote;
    late AuthLocalDataSource local;
    late StreamController<SessionEndReason> expired;
    late AuthRepositoryImpl repository;

    setUp(() {
      remote = FakeAuthRemoteDataSource();
      final store = InMemorySecureStore();
      local = AuthLocalDataSourceImpl(
        store: store,
        tokenStorage: SecureTokenStorage(store),
      );
      expired = StreamController<SessionEndReason>.broadcast();
      repository = AuthRepositoryImpl(
        remote: remote,
        local: local,
        sessionExpired: expired.stream,
      );
    });

    tearDown(() => expired.close());

    Future<bool?> loginHead({
      required bool loginSays,
      bool? meSays,
    }) async {
      remote
        ..loginResponse = testTokens(isDepartmentHead: loginSays)
        ..profile = testUserModel(isDepartmentHead: meSays);
      final result = await repository.login(email: 'a@b.la', password: 'p');
      return result.dataOrNull?.user?.isDepartmentHead;
    }

    test('/auth/me says: it wins over the login answer', () async {
      expect(await loginHead(loginSays: false, meSays: true), isTrue);
      expect(await loginHead(loginSays: true, meSays: false), isFalse);
    });

    test('/auth/me does not say (an older server): the login answer counts, '
        'and is kept in the cached user', () async {
      expect(await loginHead(loginSays: true), isTrue);
      expect((await local.readUser())?.isDepartmentHead, isTrue);
    });

    test('a restart offline keeps it from the cache', () async {
      await loginHead(loginSays: true, meSays: true);
      remote.profileError = Exception('offline');

      final restored = await repository.restoreSession();

      expect(restored.dataOrNull?.user?.isDepartmentHead, isTrue);
    });

    test('a restart online takes the fresh value: made head, or no longer',
        () async {
      await loginHead(loginSays: false, meSays: false);
      remote.profile = testUserModel(isDepartmentHead: true);

      final restored = await repository.restoreSession();

      expect(restored.dataOrNull?.user?.isDepartmentHead, isTrue);
    });

    test('a restart online with an older server keeps the cached value',
        () async {
      await loginHead(loginSays: true);
      remote.profile = testUserModel();

      final restored = await repository.restoreSession();

      expect(restored.dataOrNull?.user?.isDepartmentHead, isTrue);
    });

    test('fetchProfile (the refresh on resume) takes the fresh value', () async {
      await loginHead(loginSays: true, meSays: true);
      remote.profile = testUserModel(isDepartmentHead: false);

      final user = await repository.fetchProfile();

      expect(user.dataOrNull?.isDepartmentHead, isFalse);
    });

    test('an older server on refresh keeps what was known', () async {
      await loginHead(loginSays: true);
      remote.profile = testUserModel();

      final user = await repository.fetchProfile();

      expect(user.dataOrNull?.isDepartmentHead, isTrue);
    });

    test('a refresh answering after sign-out is not saved on the phone',
        () async {
      await loginHead(loginSays: true, meSays: true);
      final slow = Completer<void>();
      remote.holdProfile = slow;

      final refresh = repository.fetchProfile();
      await repository.logout();
      slow.complete();
      await refresh;

      expect(await local.readUser(), isNull);
    });

    test('a refresh answering after another user signed in does not '
        'overwrite their saved profile', () async {
      await loginHead(loginSays: true, meSays: true);
      final slow = Completer<void>();
      remote.holdProfile = slow;

      final refresh = repository.fetchProfile();
      await repository.logout();
      remote
        ..loginResponse = testTokens()
        ..profile = testUserModel(id: 'someone-else', isDepartmentHead: false);
      await repository.login(email: 'b@c.la', password: 'p');
      slow.complete();
      await refresh;

      final saved = await local.readUser();
      expect(saved?.id, 'someone-else');
      expect(saved?.isDepartmentHead, isFalse);
    });

    test('sign-out drops it: the next login on the phone starts clean',
        () async {
      await loginHead(loginSays: true, meSays: true);

      await repository.logout();

      expect(await local.readUser(), isNull);
    });
  });
}
