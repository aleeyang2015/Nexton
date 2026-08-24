// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AttendanceState {
  /// Today's record. Starts as data-with-empty rather than loading, so the
  /// card paints its "not checked in" resting state immediately instead of
  /// flashing a spinner on every cold start.
  AsyncValue<AttendanceDay> get today => throw _privateConstructorUsedError;

  /// A punch is in flight. §7 rule 8 asks the client to suppress repeats
  /// itself rather than lean on the backend's session guard.
  bool get isPunching => throw _privateConstructorUsedError;

  /// Set when the backend throttles a punch (429). Until it passes, the
  /// slide action is inert — §7 rule 10's cooldown.
  DateTime? get cooldownUntil => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AttendanceStateCopyWith<AttendanceState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttendanceStateCopyWith<$Res> {
  factory $AttendanceStateCopyWith(
    AttendanceState value,
    $Res Function(AttendanceState) then,
  ) = _$AttendanceStateCopyWithImpl<$Res, AttendanceState>;
  @useResult
  $Res call({
    AsyncValue<AttendanceDay> today,
    bool isPunching,
    DateTime? cooldownUntil,
  });
}

/// @nodoc
class _$AttendanceStateCopyWithImpl<$Res, $Val extends AttendanceState>
    implements $AttendanceStateCopyWith<$Res> {
  _$AttendanceStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? today = null,
    Object? isPunching = null,
    Object? cooldownUntil = freezed,
  }) {
    return _then(
      _value.copyWith(
            today: null == today
                ? _value.today
                : today // ignore: cast_nullable_to_non_nullable
                      as AsyncValue<AttendanceDay>,
            isPunching: null == isPunching
                ? _value.isPunching
                : isPunching // ignore: cast_nullable_to_non_nullable
                      as bool,
            cooldownUntil: freezed == cooldownUntil
                ? _value.cooldownUntil
                : cooldownUntil // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AttendanceStateImplCopyWith<$Res>
    implements $AttendanceStateCopyWith<$Res> {
  factory _$$AttendanceStateImplCopyWith(
    _$AttendanceStateImpl value,
    $Res Function(_$AttendanceStateImpl) then,
  ) = __$$AttendanceStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    AsyncValue<AttendanceDay> today,
    bool isPunching,
    DateTime? cooldownUntil,
  });
}

/// @nodoc
class __$$AttendanceStateImplCopyWithImpl<$Res>
    extends _$AttendanceStateCopyWithImpl<$Res, _$AttendanceStateImpl>
    implements _$$AttendanceStateImplCopyWith<$Res> {
  __$$AttendanceStateImplCopyWithImpl(
    _$AttendanceStateImpl _value,
    $Res Function(_$AttendanceStateImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? today = null,
    Object? isPunching = null,
    Object? cooldownUntil = freezed,
  }) {
    return _then(
      _$AttendanceStateImpl(
        today: null == today
            ? _value.today
            : today // ignore: cast_nullable_to_non_nullable
                  as AsyncValue<AttendanceDay>,
        isPunching: null == isPunching
            ? _value.isPunching
            : isPunching // ignore: cast_nullable_to_non_nullable
                  as bool,
        cooldownUntil: freezed == cooldownUntil
            ? _value.cooldownUntil
            : cooldownUntil // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$AttendanceStateImpl extends _AttendanceState {
  const _$AttendanceStateImpl({
    this.today = const AsyncValue.data(AttendanceDay.empty),
    this.isPunching = false,
    this.cooldownUntil,
  }) : super._();

  /// Today's record. Starts as data-with-empty rather than loading, so the
  /// card paints its "not checked in" resting state immediately instead of
  /// flashing a spinner on every cold start.
  @override
  @JsonKey()
  final AsyncValue<AttendanceDay> today;

  /// A punch is in flight. §7 rule 8 asks the client to suppress repeats
  /// itself rather than lean on the backend's session guard.
  @override
  @JsonKey()
  final bool isPunching;

  /// Set when the backend throttles a punch (429). Until it passes, the
  /// slide action is inert — §7 rule 10's cooldown.
  @override
  final DateTime? cooldownUntil;

  @override
  String toString() {
    return 'AttendanceState(today: $today, isPunching: $isPunching, cooldownUntil: $cooldownUntil)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttendanceStateImpl &&
            (identical(other.today, today) || other.today == today) &&
            (identical(other.isPunching, isPunching) ||
                other.isPunching == isPunching) &&
            (identical(other.cooldownUntil, cooldownUntil) ||
                other.cooldownUntil == cooldownUntil));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, today, isPunching, cooldownUntil);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AttendanceStateImplCopyWith<_$AttendanceStateImpl> get copyWith =>
      __$$AttendanceStateImplCopyWithImpl<_$AttendanceStateImpl>(
        this,
        _$identity,
      );
}

abstract class _AttendanceState extends AttendanceState {
  const factory _AttendanceState({
    final AsyncValue<AttendanceDay> today,
    final bool isPunching,
    final DateTime? cooldownUntil,
  }) = _$AttendanceStateImpl;
  const _AttendanceState._() : super._();

  @override
  /// Today's record. Starts as data-with-empty rather than loading, so the
  /// card paints its "not checked in" resting state immediately instead of
  /// flashing a spinner on every cold start.
  AsyncValue<AttendanceDay> get today;
  @override
  /// A punch is in flight. §7 rule 8 asks the client to suppress repeats
  /// itself rather than lean on the backend's session guard.
  bool get isPunching;
  @override
  /// Set when the backend throttles a punch (429). Until it passes, the
  /// slide action is inert — §7 rule 10's cooldown.
  DateTime? get cooldownUntil;
  @override
  @JsonKey(ignore: true)
  _$$AttendanceStateImplCopyWith<_$AttendanceStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
