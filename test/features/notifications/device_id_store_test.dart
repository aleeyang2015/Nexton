import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/network/token_storage.dart';
import 'package:next_on/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:next_on/features/notifications/data/datasources/device_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/auth_test_doubles.dart';

/// The phone's `device_id` (#52) names the install, not the user: the same
/// across sign-outs and launches, so the server upserts one row.
void main() {
  test('the same id on every launch and across a sign-out', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = DeviceLocalDataSourceImpl(prefs).deviceId();
    expect(first, matches(RegExp(r'^[0-9a-f]{32}$')));

    // A sign-out: what the auth feature clears.
    final store = InMemorySecureStore();
    await AuthLocalDataSourceImpl(
      store: store,
      tokenStorage: SecureTokenStorage(store),
    ).clear();

    // A new launch: a new store on the same phone storage.
    expect(DeviceLocalDataSourceImpl(prefs).deviceId(), first);
  });

  test('a new install (empty storage) gets a new id', () async {
    SharedPreferences.setMockInitialValues({});
    final a = DeviceLocalDataSourceImpl(
      await SharedPreferences.getInstance(),
    ).deviceId();
    SharedPreferences.setMockInitialValues({});
    final b = DeviceLocalDataSourceImpl(
      await SharedPreferences.getInstance(),
    ).deviceId();
    expect(a, isNot(b));
  });
}
