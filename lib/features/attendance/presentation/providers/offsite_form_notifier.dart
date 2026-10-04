import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../attendance_providers.dart';
import '../../domain/datasources/punch_location_source.dart';
import '../../domain/entities/offsite_method.dart';
import '../../domain/entities/offsite_outcome.dart';
import 'offsite_form_state.dart';
import 'offsite_photo_notifier.dart';

/// Fields, rules and submission of the off-site scan request form
/// ("ສະແກນນອກພື້ນທີ່").
///
/// The position is read when the form opens, because the employee is standing
/// where the scan happened *now* — asking them to press a button for it first
/// would only add a step to a flow they reached by being refused a punch.
class OffsiteFormNotifier extends AutoDisposeNotifier<OffsiteFormState> {
  @override
  OffsiteFormState build() {
    // The photo is owned by its own notifier (it uploads as soon as it is
    // picked); the form keeps the accepted file so it can refuse to submit
    // without one.
    ref.listen(offsitePhotoNotifierProvider, (_, next) {
      if (next.isLoading) return;
      state = state.copyWith(photo: next.valueOrNull?.uploaded);
    });

    // Deferred to a microtask: `readLocation` writes to `state`, which can
    // only happen once build() has returned one.
    Future.microtask(readLocation);
    return const OffsiteFormState();
  }

  void setMethod(OffsiteMethod method) =>
      state = state.copyWith(method: method);

  void setReason(String reason) => state = state.copyWith(reason: reason);

  /// Reads the device's position into [OffsiteFormState.location]. Called once
  /// when the form opens, and again from the location card's retry.
  Future<void> readLocation() async {
    state = state.copyWith(
      location: const AsyncValue<PunchLocationReading>.loading()
          .copyWithPrevious(state.location),
    );

    final result = await ref.read(readOffsiteLocationUseCaseProvider)();

    state = state.copyWith(
      location: result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        AsyncValue.data,
      ),
    );
  }

  /// Validates the form and files the request.
  ///
  /// Returns the backend's answer — which may be [OffsiteBlocked], a refusal
  /// the user can act on — or null when the request never got one, in which
  /// case the reason is in `state.submission`'s error.
  Future<OffsiteOutcome?> submit() async {
    if (state.isSubmitting || state.isLocating) return null;

    final request = state.toRequest();
    final validation = request.validate();
    if (validation.isFailure) {
      state = state.copyWith(
        showErrors: true,
        submission: AsyncValue.error(
          validation.failureOrNull!,
          StackTrace.current,
        ),
      );
      return null;
    }

    state = state.copyWith(submission: const AsyncValue.loading());

    final result = await ref.read(submitOffsiteRequestUseCaseProvider)(request);

    return result.fold(
      (failure) {
        state = state.copyWith(
          submission: AsyncValue.error(failure, StackTrace.current),
        );
        return null;
      },
      (outcome) {
        state = state.copyWith(submission: const AsyncValue.data(null));
        return outcome;
      },
    );
  }
}

final offsiteFormNotifierProvider =
    NotifierProvider.autoDispose<OffsiteFormNotifier, OffsiteFormState>(
      OffsiteFormNotifier.new,
    );
