import '../../../../core/utils/result.dart';
import '../datasources/punch_location_source.dart';
import '../entities/clock_method.dart';
import '../entities/punch_request.dart';

/// Reads the position an off-site scan request is filed from.
///
/// The reading is checked through [PunchRequest.validate] rather than by rules
/// of its own, so an off-site scan refuses a spoofed position and explains a
/// missing one — services off, permission denied, denied forever, no fix in
/// time — in exactly the words a GPS punch uses (§7 rules 1–2).
class ReadOffsiteLocationUseCase {
  final PunchLocationSource _locationSource;

  ReadOffsiteLocationUseCase(this._locationSource);

  /// The current position, or a [ValidationFailure] naming what is missing.
  Future<Result<PunchLocationReading>> call() async {
    late final PunchLocationReading reading;
    try {
      reading = await _locationSource.read(ClockMethod.gps);
    } catch (_) {
      // A source that throws read nothing; validate() names the signal.
      reading = PunchLocationReading.unavailable;
    }

    final check = PunchRequest(
      method: ClockMethod.gps,
      reading: reading,
    ).validate();

    return check.fold(
      Result<PunchLocationReading>.failure,
      (_) => Result.success(reading),
    );
  }
}
