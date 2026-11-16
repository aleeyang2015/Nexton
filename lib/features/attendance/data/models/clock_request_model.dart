import '../../domain/entities/punch_request.dart';

/// Serialises a [PunchRequest] into the body §3 documents. Clock-in and
/// clock-out share it — §4 says both endpoints take the same shape.
class ClockRequestModel {
  final PunchRequest request;

  const ClockRequestModel(this.request);

  /// Optional fields are omitted rather than sent as null, matching the
  /// spec's own Dart sample.
  ///
  /// One deliberate difference: `is_mock_location` is omitted when the device
  /// could not be checked, where the sample always sends a bool. Sending
  /// `false` would assert the app verified something it did not; leaving it
  /// out lets the backend apply its own default.
  Map<String, dynamic> toJson() {
    final reading = request.reading;
    final notes = request.notes?.trim();

    return {
      'method': request.method.wireValue,
      if (reading.latitude != null) 'latitude': reading.latitude,
      if (reading.longitude != null) 'longitude': reading.longitude,
      if (reading.gpsAccuracy != null) 'gps_accuracy': reading.gpsAccuracy,
      if (reading.isMockLocation != null)
        'is_mock_location': reading.isMockLocation,
      if (request.deviceId != null) 'device_id': request.deviceId,
      if (request.photoUrl != null) 'photo_url': request.photoUrl,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
  }
}
