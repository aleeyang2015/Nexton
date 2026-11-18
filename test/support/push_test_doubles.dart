import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:next_on/features/auth/domain/entities/auth_session.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';
import 'package:next_on/features/notifications/data/datasources/device_local_data_source.dart';
import 'package:next_on/features/notifications/data/datasources/device_remote_data_source.dart';
import 'package:next_on/features/notifications/data/datasources/firebase_messaging_data_source.dart';
import 'package:next_on/features/notifications/data/datasources/local_notification_data_source.dart';
import 'package:next_on/features/notifications/data/models/device_registration_model.dart';
import 'package:next_on/features/notifications/domain/entities/push_message.dart';

import 'approver_access_test_doubles.dart';

/// A session a push test can sign in and out (#51, #52).
class FakePushSession extends AuthSessionNotifier {
  FakePushSession({required this.signedIn});

  final bool signedIn;

  @override
  Future<AuthSession> build() async => signedIn
      ? AuthSession.signedIn(approverTestUser())
      : const AuthSession.unauthenticated();

  void signIn() =>
      state = AsyncValue.data(AuthSession.signedIn(approverTestUser()));

  void signOut() =>
      state = const AsyncValue.data(AuthSession.unauthenticated());
}

/// Firebase messaging, by hand.
class FakeMessaging implements FirebaseMessagingDataSource {
  int permissionAsks = 0;
  int tokenReads = 0;
  int tokenDeletes = 0;
  bool allows = true;
  bool throwOnPermission = false;
  String token = 'fcm-token';

  /// When set, the prompt stays open until it completes.
  Completer<void>? holdPermission;

  /// Token refreshes, as the plugin would send them.
  final refresh = StreamController<String>.broadcast();

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    await holdPermission?.future;
    if (throwOnPermission) throw Exception('plugin failed');
    return allows;
  }

  @override
  Future<String?> getToken() async {
    tokenReads++;
    return token;
  }

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Stream<PushMessage> get onMessage => const Stream.empty();

  @override
  Future<void> deleteToken() async => tokenDeletes++;
}

/// The backend's device calls, recorded; each can be made to fail.
class FakeDeviceRemote implements DeviceRemoteDataSource {
  final List<DeviceRegistrationModel> registered = [];
  final List<({String deviceId, String token})> updated = [];
  final List<String> unregistered = [];

  int get registrations => registered.length;

  /// False: the server has no active row (`404` on `PUT`).
  bool updateFindsRow = true;
  Object? registerError;
  Object? unregisterError;

  /// When set, `DELETE` waits for it.
  Completer<void>? holdUnregister;

  /// Called at `DELETE`, to tell its order against other calls.
  void Function()? onUnregister;

  @override
  Future<void> register(DeviceRegistrationModel body) async {
    registered.add(body);
    final error = registerError;
    if (error != null) throw error;
  }

  @override
  Future<bool> updateToken(String deviceId, String deviceToken) async {
    updated.add((deviceId: deviceId, token: deviceToken));
    return updateFindsRow;
  }

  @override
  Future<void> unregister(String deviceId) async {
    onUnregister?.call();
    unregistered.add(deviceId);
    await holdUnregister?.future;
    final error = unregisterError;
    if (error != null) throw error;
  }
}

/// A phone store whose "already asked" cannot be saved.
class FailingDeviceStore implements DeviceLocalDataSource {
  @override
  String deviceId() => 'device-1';

  @override
  bool permissionAsked() => false;

  @override
  Future<void> markPermissionAsked() async => throw Exception('prefs');
}

/// No pop-ups in tests.
class NoPopups implements LocalNotificationDataSource {
  @override
  Future<void> show(PushMessage message) async {}
}
