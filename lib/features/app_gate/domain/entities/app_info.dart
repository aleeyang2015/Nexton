import 'package:equatable/equatable.dart';

/// The server's word on this App build (#57, `GET /mobile/app-info`): one
/// record per platform, for every company at once.
class AppInfo extends Equatable {
  /// True when the version sent is lower than the minimum the server needs.
  final bool forceUpdate;
  final bool isMaintenance;
  final String? maintenanceMessage;
  final String? maintenanceMessageLo;

  /// Where to update, when the server names a place.
  final String? updateUrl;

  const AppInfo({
    required this.forceUpdate,
    required this.isMaintenance,
    this.maintenanceMessage,
    this.maintenanceMessageLo,
    this.updateUrl,
  });

  @override
  List<Object?> get props => [
    forceUpdate,
    isMaintenance,
    maintenanceMessage,
    maintenanceMessageLo,
    updateUrl,
  ];
}
