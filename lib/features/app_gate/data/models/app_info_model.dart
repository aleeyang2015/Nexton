import '../../domain/entities/app_info.dart';

/// Reads the `GET /mobile/app-info` answer (#57). The optional texts are
/// left out by the server when empty; a flag that is missing or not a bool
/// reads as false: nothing then stops the App.
abstract final class AppInfoModel {
  static AppInfo fromJson(Map<String, dynamic> json) => AppInfo(
    forceUpdate: json['force_update'] == true,
    isMaintenance: json['is_maintenance'] == true,
    maintenanceMessage: _text(json['maintenance_message']),
    maintenanceMessageLo: _text(json['maintenance_message_lo']),
    updateUrl: _text(json['update_url']),
  );

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}
