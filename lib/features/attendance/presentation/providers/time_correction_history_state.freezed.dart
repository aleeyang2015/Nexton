// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'time_correction_history_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TimeCorrectionHistoryState {
  AsyncValue<List<TimeCorrectionRecord>> get records =>
      throw _privateConstructorUsedError;
  TimeCorrectionStatus? get filter => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TimeCorrectionHistoryStateCopyWith<TimeCorrectionHistoryState>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimeCorrectionHistoryStateCopyWith<$Res> {
  factory $TimeCorrectionHistoryStateCopyWith(
    TimeCorrectionHistoryState value,
    $Res Function(TimeCorrectionHistoryState) then,
  ) =
      _$TimeCorrectionHistoryStateCopyWithImpl<
        $Res,
        TimeCorrectionHistoryState
      >;
  @useResult
  $Res call({
    AsyncValue<List<TimeCorrectionRecord>> records,
    TimeCorrectionStatus? filter,
  });
}

/// @nodoc
class _$TimeCorrectionHistoryStateCopyWithImpl<
  $Res,
  $Val extends TimeCorrectionHistoryState
>
    implements $TimeCorrectionHistoryStateCopyWith<$Res> {
  _$TimeCorrectionHistoryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? records = null, Object? filter = freezed}) {
    return _then(
      _value.copyWith(
            records: null == records
                ? _value.records
                : records // ignore: cast_nullable_to_non_nullable
                      as AsyncValue<List<TimeCorrectionRecord>>,
            filter: freezed == filter
                ? _value.filter
                : filter // ignore: cast_nullable_to_non_nullable
                      as TimeCorrectionStatus?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TimeCorrectionHistoryStateImplCopyWith<$Res>
    implements $TimeCorrectionHistoryStateCopyWith<$Res> {
  factory _$$TimeCorrectionHistoryStateImplCopyWith(
    _$TimeCorrectionHistoryStateImpl value,
    $Res Function(_$TimeCorrectionHistoryStateImpl) then,
  ) = __$$TimeCorrectionHistoryStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    AsyncValue<List<TimeCorrectionRecord>> records,
    TimeCorrectionStatus? filter,
  });
}

/// @nodoc
class __$$TimeCorrectionHistoryStateImplCopyWithImpl<$Res>
    extends
        _$TimeCorrectionHistoryStateCopyWithImpl<
          $Res,
          _$TimeCorrectionHistoryStateImpl
        >
    implements _$$TimeCorrectionHistoryStateImplCopyWith<$Res> {
  __$$TimeCorrectionHistoryStateImplCopyWithImpl(
    _$TimeCorrectionHistoryStateImpl _value,
    $Res Function(_$TimeCorrectionHistoryStateImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? records = null, Object? filter = freezed}) {
    return _then(
      _$TimeCorrectionHistoryStateImpl(
        records: null == records
            ? _value.records
            : records // ignore: cast_nullable_to_non_nullable
                  as AsyncValue<List<TimeCorrectionRecord>>,
        filter: freezed == filter
            ? _value.filter
            : filter // ignore: cast_nullable_to_non_nullable
                  as TimeCorrectionStatus?,
      ),
    );
  }
}

/// @nodoc

class _$TimeCorrectionHistoryStateImpl extends _TimeCorrectionHistoryState {
  const _$TimeCorrectionHistoryStateImpl({
    this.records = const AsyncValue<List<TimeCorrectionRecord>>.loading(),
    this.filter,
  }) : super._();

  @override
  @JsonKey()
  final AsyncValue<List<TimeCorrectionRecord>> records;
  @override
  final TimeCorrectionStatus? filter;

  @override
  String toString() {
    return 'TimeCorrectionHistoryState(records: $records, filter: $filter)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimeCorrectionHistoryStateImpl &&
            (identical(other.records, records) || other.records == records) &&
            (identical(other.filter, filter) || other.filter == filter));
  }

  @override
  int get hashCode => Object.hash(runtimeType, records, filter);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TimeCorrectionHistoryStateImplCopyWith<_$TimeCorrectionHistoryStateImpl>
  get copyWith =>
      __$$TimeCorrectionHistoryStateImplCopyWithImpl<
        _$TimeCorrectionHistoryStateImpl
      >(this, _$identity);
}

abstract class _TimeCorrectionHistoryState extends TimeCorrectionHistoryState {
  const factory _TimeCorrectionHistoryState({
    final AsyncValue<List<TimeCorrectionRecord>> records,
    final TimeCorrectionStatus? filter,
  }) = _$TimeCorrectionHistoryStateImpl;
  const _TimeCorrectionHistoryState._() : super._();

  @override
  AsyncValue<List<TimeCorrectionRecord>> get records;
  @override
  TimeCorrectionStatus? get filter;
  @override
  @JsonKey(ignore: true)
  _$$TimeCorrectionHistoryStateImplCopyWith<_$TimeCorrectionHistoryStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
