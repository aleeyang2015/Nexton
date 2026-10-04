// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offsite_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$OffsiteFormState {
  /// The menu is reached when a clock-out lands outside every geofence, so
  /// that is where the form starts; the employee can switch it.
  OffsiteMethod get method => throw _privateConstructorUsedError;
  AsyncValue<PunchLocationReading> get location =>
      throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  UploadedAttachment? get photo => throw _privateConstructorUsedError;
  bool get showErrors => throw _privateConstructorUsedError;
  AsyncValue<void> get submission => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $OffsiteFormStateCopyWith<OffsiteFormState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OffsiteFormStateCopyWith<$Res> {
  factory $OffsiteFormStateCopyWith(
          OffsiteFormState value, $Res Function(OffsiteFormState) then) =
      _$OffsiteFormStateCopyWithImpl<$Res, OffsiteFormState>;
  @useResult
  $Res call(
      {OffsiteMethod method,
      AsyncValue<PunchLocationReading> location,
      String reason,
      UploadedAttachment? photo,
      bool showErrors,
      AsyncValue<void> submission});
}

/// @nodoc
class _$OffsiteFormStateCopyWithImpl<$Res, $Val extends OffsiteFormState>
    implements $OffsiteFormStateCopyWith<$Res> {
  _$OffsiteFormStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? method = null,
    Object? location = null,
    Object? reason = null,
    Object? photo = freezed,
    Object? showErrors = null,
    Object? submission = null,
  }) {
    return _then(_value.copyWith(
      method: null == method
          ? _value.method
          : method // ignore: cast_nullable_to_non_nullable
              as OffsiteMethod,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as AsyncValue<PunchLocationReading>,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      photo: freezed == photo
          ? _value.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as UploadedAttachment?,
      showErrors: null == showErrors
          ? _value.showErrors
          : showErrors // ignore: cast_nullable_to_non_nullable
              as bool,
      submission: null == submission
          ? _value.submission
          : submission // ignore: cast_nullable_to_non_nullable
              as AsyncValue<void>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OffsiteFormStateImplCopyWith<$Res>
    implements $OffsiteFormStateCopyWith<$Res> {
  factory _$$OffsiteFormStateImplCopyWith(_$OffsiteFormStateImpl value,
          $Res Function(_$OffsiteFormStateImpl) then) =
      __$$OffsiteFormStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {OffsiteMethod method,
      AsyncValue<PunchLocationReading> location,
      String reason,
      UploadedAttachment? photo,
      bool showErrors,
      AsyncValue<void> submission});
}

/// @nodoc
class __$$OffsiteFormStateImplCopyWithImpl<$Res>
    extends _$OffsiteFormStateCopyWithImpl<$Res, _$OffsiteFormStateImpl>
    implements _$$OffsiteFormStateImplCopyWith<$Res> {
  __$$OffsiteFormStateImplCopyWithImpl(_$OffsiteFormStateImpl _value,
      $Res Function(_$OffsiteFormStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? method = null,
    Object? location = null,
    Object? reason = null,
    Object? photo = freezed,
    Object? showErrors = null,
    Object? submission = null,
  }) {
    return _then(_$OffsiteFormStateImpl(
      method: null == method
          ? _value.method
          : method // ignore: cast_nullable_to_non_nullable
              as OffsiteMethod,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as AsyncValue<PunchLocationReading>,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      photo: freezed == photo
          ? _value.photo
          : photo // ignore: cast_nullable_to_non_nullable
              as UploadedAttachment?,
      showErrors: null == showErrors
          ? _value.showErrors
          : showErrors // ignore: cast_nullable_to_non_nullable
              as bool,
      submission: null == submission
          ? _value.submission
          : submission // ignore: cast_nullable_to_non_nullable
              as AsyncValue<void>,
    ));
  }
}

/// @nodoc

class _$OffsiteFormStateImpl extends _OffsiteFormState {
  const _$OffsiteFormStateImpl(
      {this.method = OffsiteMethod.checkOut,
      this.location = const AsyncValue<PunchLocationReading>.loading(),
      this.reason = '',
      this.photo,
      this.showErrors = false,
      this.submission = const AsyncValue<void>.data(null)})
      : super._();

  /// The menu is reached when a clock-out lands outside every geofence, so
  /// that is where the form starts; the employee can switch it.
  @override
  @JsonKey()
  final OffsiteMethod method;
  @override
  @JsonKey()
  final AsyncValue<PunchLocationReading> location;
  @override
  @JsonKey()
  final String reason;
  @override
  final UploadedAttachment? photo;
  @override
  @JsonKey()
  final bool showErrors;
  @override
  @JsonKey()
  final AsyncValue<void> submission;

  @override
  String toString() {
    return 'OffsiteFormState(method: $method, location: $location, reason: $reason, photo: $photo, showErrors: $showErrors, submission: $submission)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OffsiteFormStateImpl &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.photo, photo) || other.photo == photo) &&
            (identical(other.showErrors, showErrors) ||
                other.showErrors == showErrors) &&
            (identical(other.submission, submission) ||
                other.submission == submission));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, method, location, reason, photo, showErrors, submission);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OffsiteFormStateImplCopyWith<_$OffsiteFormStateImpl> get copyWith =>
      __$$OffsiteFormStateImplCopyWithImpl<_$OffsiteFormStateImpl>(
          this, _$identity);
}

abstract class _OffsiteFormState extends OffsiteFormState {
  const factory _OffsiteFormState(
      {final OffsiteMethod method,
      final AsyncValue<PunchLocationReading> location,
      final String reason,
      final UploadedAttachment? photo,
      final bool showErrors,
      final AsyncValue<void> submission}) = _$OffsiteFormStateImpl;
  const _OffsiteFormState._() : super._();

  @override

  /// The menu is reached when a clock-out lands outside every geofence, so
  /// that is where the form starts; the employee can switch it.
  OffsiteMethod get method;
  @override
  AsyncValue<PunchLocationReading> get location;
  @override
  String get reason;
  @override
  UploadedAttachment? get photo;
  @override
  bool get showErrors;
  @override
  AsyncValue<void> get submission;
  @override
  @JsonKey(ignore: true)
  _$$OffsiteFormStateImplCopyWith<_$OffsiteFormStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
