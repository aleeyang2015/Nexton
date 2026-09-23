// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'time_correction_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TimeCorrectionFormState {
  DateTime get date => throw _privateConstructorUsedError;
  TimeCorrectionType get type => throw _privateConstructorUsedError;
  WorkShift? get shift => throw _privateConstructorUsedError;
  TimeOfDay get clockIn => throw _privateConstructorUsedError;
  TimeOfDay get clockOut => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  LocalFile? get attachment => throw _privateConstructorUsedError;
  int? get attachmentBytes => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TimeCorrectionFormStateCopyWith<TimeCorrectionFormState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimeCorrectionFormStateCopyWith<$Res> {
  factory $TimeCorrectionFormStateCopyWith(
    TimeCorrectionFormState value,
    $Res Function(TimeCorrectionFormState) then,
  ) = _$TimeCorrectionFormStateCopyWithImpl<$Res, TimeCorrectionFormState>;
  @useResult
  $Res call({
    DateTime date,
    TimeCorrectionType type,
    WorkShift? shift,
    TimeOfDay clockIn,
    TimeOfDay clockOut,
    String reason,
    LocalFile? attachment,
    int? attachmentBytes,
  });
}

/// @nodoc
class _$TimeCorrectionFormStateCopyWithImpl<
  $Res,
  $Val extends TimeCorrectionFormState
>
    implements $TimeCorrectionFormStateCopyWith<$Res> {
  _$TimeCorrectionFormStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? type = null,
    Object? shift = freezed,
    Object? clockIn = null,
    Object? clockOut = null,
    Object? reason = null,
    Object? attachment = freezed,
    Object? attachmentBytes = freezed,
  }) {
    return _then(
      _value.copyWith(
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as TimeCorrectionType,
            shift: freezed == shift
                ? _value.shift
                : shift // ignore: cast_nullable_to_non_nullable
                      as WorkShift?,
            clockIn: null == clockIn
                ? _value.clockIn
                : clockIn // ignore: cast_nullable_to_non_nullable
                      as TimeOfDay,
            clockOut: null == clockOut
                ? _value.clockOut
                : clockOut // ignore: cast_nullable_to_non_nullable
                      as TimeOfDay,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
            attachment: freezed == attachment
                ? _value.attachment
                : attachment // ignore: cast_nullable_to_non_nullable
                      as LocalFile?,
            attachmentBytes: freezed == attachmentBytes
                ? _value.attachmentBytes
                : attachmentBytes // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TimeCorrectionFormStateImplCopyWith<$Res>
    implements $TimeCorrectionFormStateCopyWith<$Res> {
  factory _$$TimeCorrectionFormStateImplCopyWith(
    _$TimeCorrectionFormStateImpl value,
    $Res Function(_$TimeCorrectionFormStateImpl) then,
  ) = __$$TimeCorrectionFormStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    DateTime date,
    TimeCorrectionType type,
    WorkShift? shift,
    TimeOfDay clockIn,
    TimeOfDay clockOut,
    String reason,
    LocalFile? attachment,
    int? attachmentBytes,
  });
}

/// @nodoc
class __$$TimeCorrectionFormStateImplCopyWithImpl<$Res>
    extends
        _$TimeCorrectionFormStateCopyWithImpl<
          $Res,
          _$TimeCorrectionFormStateImpl
        >
    implements _$$TimeCorrectionFormStateImplCopyWith<$Res> {
  __$$TimeCorrectionFormStateImplCopyWithImpl(
    _$TimeCorrectionFormStateImpl _value,
    $Res Function(_$TimeCorrectionFormStateImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? type = null,
    Object? shift = freezed,
    Object? clockIn = null,
    Object? clockOut = null,
    Object? reason = null,
    Object? attachment = freezed,
    Object? attachmentBytes = freezed,
  }) {
    return _then(
      _$TimeCorrectionFormStateImpl(
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as TimeCorrectionType,
        shift: freezed == shift
            ? _value.shift
            : shift // ignore: cast_nullable_to_non_nullable
                  as WorkShift?,
        clockIn: null == clockIn
            ? _value.clockIn
            : clockIn // ignore: cast_nullable_to_non_nullable
                  as TimeOfDay,
        clockOut: null == clockOut
            ? _value.clockOut
            : clockOut // ignore: cast_nullable_to_non_nullable
                  as TimeOfDay,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
        attachment: freezed == attachment
            ? _value.attachment
            : attachment // ignore: cast_nullable_to_non_nullable
                  as LocalFile?,
        attachmentBytes: freezed == attachmentBytes
            ? _value.attachmentBytes
            : attachmentBytes // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$TimeCorrectionFormStateImpl extends _TimeCorrectionFormState {
  const _$TimeCorrectionFormStateImpl({
    required this.date,
    this.type = TimeCorrectionType.both,
    this.shift,
    this.clockIn = const TimeOfDay(hour: 8, minute: 0),
    this.clockOut = const TimeOfDay(hour: 17, minute: 0),
    this.reason = '',
    this.attachment,
    this.attachmentBytes,
  }) : super._();

  @override
  final DateTime date;
  @override
  @JsonKey()
  final TimeCorrectionType type;
  @override
  final WorkShift? shift;
  @override
  @JsonKey()
  final TimeOfDay clockIn;
  @override
  @JsonKey()
  final TimeOfDay clockOut;
  @override
  @JsonKey()
  final String reason;
  @override
  final LocalFile? attachment;
  @override
  final int? attachmentBytes;

  @override
  String toString() {
    return 'TimeCorrectionFormState(date: $date, type: $type, shift: $shift, clockIn: $clockIn, clockOut: $clockOut, reason: $reason, attachment: $attachment, attachmentBytes: $attachmentBytes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimeCorrectionFormStateImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.shift, shift) || other.shift == shift) &&
            (identical(other.clockIn, clockIn) || other.clockIn == clockIn) &&
            (identical(other.clockOut, clockOut) ||
                other.clockOut == clockOut) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.attachment, attachment) ||
                other.attachment == attachment) &&
            (identical(other.attachmentBytes, attachmentBytes) ||
                other.attachmentBytes == attachmentBytes));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    date,
    type,
    shift,
    clockIn,
    clockOut,
    reason,
    attachment,
    attachmentBytes,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TimeCorrectionFormStateImplCopyWith<_$TimeCorrectionFormStateImpl>
  get copyWith =>
      __$$TimeCorrectionFormStateImplCopyWithImpl<
        _$TimeCorrectionFormStateImpl
      >(this, _$identity);
}

abstract class _TimeCorrectionFormState extends TimeCorrectionFormState {
  const factory _TimeCorrectionFormState({
    required final DateTime date,
    final TimeCorrectionType type,
    final WorkShift? shift,
    final TimeOfDay clockIn,
    final TimeOfDay clockOut,
    final String reason,
    final LocalFile? attachment,
    final int? attachmentBytes,
  }) = _$TimeCorrectionFormStateImpl;
  const _TimeCorrectionFormState._() : super._();

  @override
  DateTime get date;
  @override
  TimeCorrectionType get type;
  @override
  WorkShift? get shift;
  @override
  TimeOfDay get clockIn;
  @override
  TimeOfDay get clockOut;
  @override
  String get reason;
  @override
  LocalFile? get attachment;
  @override
  int? get attachmentBytes;
  @override
  @JsonKey(ignore: true)
  _$$TimeCorrectionFormStateImplCopyWith<_$TimeCorrectionFormStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
