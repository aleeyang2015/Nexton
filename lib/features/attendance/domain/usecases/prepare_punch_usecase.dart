import '../../../../core/utils/result.dart';
import '../datasources/punch_location_source.dart';
import '../entities/clock_method.dart';
import '../entities/punch_request.dart';

/// Gathers the device evidence for a punch and checks it before anything is
/// sent (§7 rules 1–3).
///
/// Kept separate from [ClockInUseCase]/[ClockOutUseCase] for one concrete
/// reason: the early-checkout retry must re-send the *same* reading. If the
/// punch use cases sampled the location themselves, the retry would read a
/// fresh position minutes later — from wherever the phone had wandered while
/// the reason dialog was open — and could fail a geofence the first attempt
/// passed.
class PreparePunchUseCase {
  final PunchLocationSource _locationSource;

  PreparePunchUseCase(this._locationSource);

  /// Reads the signals [method] needs and returns a validated request.
  ///
  /// A missing signal comes back as a [ValidationFailure] naming the field,
  /// never as a request that is certain to be rejected.
  Future<Result<PunchRequest>> call(
    ClockMethod method, {
    String? fieldWorkReason,
    String? notes,
    String? photoUrl,
    String? deviceId,
  }) async {
    late final PunchLocationReading reading;
    try {
      reading = await _locationSource.read(method);
    } catch (_) {
      // A source that throws is treated as a source that read nothing;
      // validate() then names the signal that is missing.
      reading = PunchLocationReading.unavailable;
    }

    final request = PunchRequest(
      method: method,
      reading: reading,
      fieldWorkReason: fieldWorkReason,
      notes: notes,
      photoUrl: photoUrl,
      deviceId: deviceId,
    );

    final validation = request.validate();
    return validation.fold(
      Result<PunchRequest>.failure,
      (_) => Result.success(request),
    );
  }
}
