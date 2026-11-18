import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/app_gate/data/models/app_info_model.dart';
import 'package:next_on/features/app_gate/domain/entities/app_info.dart';

/// The `GET /mobile/app-info` answer (#57): the optional texts are left out
/// when empty, and nothing missing ever stops the App.
void main() {
  test('every field', () {
    final info = AppInfoModel.fromJson({
      'platform': 'android',
      'latest_version': '1.0.2',
      'minimum_required_version': '1.0.1',
      'force_update': true,
      'is_maintenance': true,
      'maintenance_message': 'Back at 10:00',
      'maintenance_message_lo': 'ກັບມາເວລາ 10:00',
      'update_url': 'https://example.com/app',
      'release_notes': 'Fixes',
    });
    expect(
      info,
      const AppInfo(
        forceUpdate: true,
        isMaintenance: true,
        maintenanceMessage: 'Back at 10:00',
        maintenanceMessageLo: 'ກັບມາເວລາ 10:00',
        updateUrl: 'https://example.com/app',
      ),
    );
  });

  test('the optional texts missing, or empty: null', () {
    final info = AppInfoModel.fromJson({
      'force_update': false,
      'is_maintenance': false,
      'maintenance_message': '  ',
    });
    expect(info.maintenanceMessage, isNull);
    expect(info.maintenanceMessageLo, isNull);
    expect(info.updateUrl, isNull);
  });

  test('a flag missing or not a bool reads as false', () {
    final info = AppInfoModel.fromJson({
      'force_update': 'yes',
      'is_maintenance': null,
    });
    expect(info.forceUpdate, isFalse);
    expect(info.isMaintenance, isFalse);
    expect(AppInfoModel.fromJson(const {}).forceUpdate, isFalse);
  });
}
