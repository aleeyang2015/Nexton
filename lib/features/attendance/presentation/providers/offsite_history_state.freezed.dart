// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offsite_history_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$OffsiteHistoryState {
  AsyncValue<List<OffsiteRequestDetail>> get requests =>
      throw _privateConstructorUsedError;
  TimeCorrectionStatus? get filter => throw _privateConstructorUsedError;
  Set<String> get cancellingIds => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $OffsiteHistoryStateCopyWith<OffsiteHistoryState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OffsiteHistoryStateCopyWith<$Res> {
  factory $OffsiteHistoryStateCopyWith(
          OffsiteHistoryState value, $Res Function(OffsiteHistoryState) then) =
      _$OffsiteHistoryStateCopyWithImpl<$Res, OffsiteHistoryState>;
  @useResult
  $Res call(
      {AsyncValue<List<OffsiteRequestDetail>> requests,
      TimeCorrectionStatus? filter,
      Set<String> cancellingIds});
}

/// @nodoc
class _$OffsiteHistoryStateCopyWithImpl<$Res, $Val extends OffsiteHistoryState>
    implements $OffsiteHistoryStateCopyWith<$Res> {
  _$OffsiteHistoryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requests = null,
    Object? filter = freezed,
    Object? cancellingIds = null,
  }) {
    return _then(_value.copyWith(
      requests: null == requests
          ? _value.requests
          : requests // ignore: cast_nullable_to_non_nullable
              as AsyncValue<List<OffsiteRequestDetail>>,
      filter: freezed == filter
          ? _value.filter
          : filter // ignore: cast_nullable_to_non_nullable
              as TimeCorrectionStatus?,
      cancellingIds: null == cancellingIds
          ? _value.cancellingIds
          : cancellingIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OffsiteHistoryStateImplCopyWith<$Res>
    implements $OffsiteHistoryStateCopyWith<$Res> {
  factory _$$OffsiteHistoryStateImplCopyWith(_$OffsiteHistoryStateImpl value,
          $Res Function(_$OffsiteHistoryStateImpl) then) =
      __$$OffsiteHistoryStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {AsyncValue<List<OffsiteRequestDetail>> requests,
      TimeCorrectionStatus? filter,
      Set<String> cancellingIds});
}

/// @nodoc
class __$$OffsiteHistoryStateImplCopyWithImpl<$Res>
    extends _$OffsiteHistoryStateCopyWithImpl<$Res, _$OffsiteHistoryStateImpl>
    implements _$$OffsiteHistoryStateImplCopyWith<$Res> {
  __$$OffsiteHistoryStateImplCopyWithImpl(_$OffsiteHistoryStateImpl _value,
      $Res Function(_$OffsiteHistoryStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requests = null,
    Object? filter = freezed,
    Object? cancellingIds = null,
  }) {
    return _then(_$OffsiteHistoryStateImpl(
      requests: null == requests
          ? _value.requests
          : requests // ignore: cast_nullable_to_non_nullable
              as AsyncValue<List<OffsiteRequestDetail>>,
      filter: freezed == filter
          ? _value.filter
          : filter // ignore: cast_nullable_to_non_nullable
              as TimeCorrectionStatus?,
      cancellingIds: null == cancellingIds
          ? _value._cancellingIds
          : cancellingIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ));
  }
}

/// @nodoc

class _$OffsiteHistoryStateImpl extends _OffsiteHistoryState {
  const _$OffsiteHistoryStateImpl(
      {this.requests = const AsyncValue<List<OffsiteRequestDetail>>.loading(),
      this.filter,
      final Set<String> cancellingIds = const <String>{}})
      : _cancellingIds = cancellingIds,
        super._();

  @override
  @JsonKey()
  final AsyncValue<List<OffsiteRequestDetail>> requests;
  @override
  final TimeCorrectionStatus? filter;
  final Set<String> _cancellingIds;
  @override
  @JsonKey()
  Set<String> get cancellingIds {
    if (_cancellingIds is EqualUnmodifiableSetView) return _cancellingIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_cancellingIds);
  }

  @override
  String toString() {
    return 'OffsiteHistoryState(requests: $requests, filter: $filter, cancellingIds: $cancellingIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OffsiteHistoryStateImpl &&
            (identical(other.requests, requests) ||
                other.requests == requests) &&
            (identical(other.filter, filter) || other.filter == filter) &&
            const DeepCollectionEquality()
                .equals(other._cancellingIds, _cancellingIds));
  }

  @override
  int get hashCode => Object.hash(runtimeType, requests, filter,
      const DeepCollectionEquality().hash(_cancellingIds));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OffsiteHistoryStateImplCopyWith<_$OffsiteHistoryStateImpl> get copyWith =>
      __$$OffsiteHistoryStateImplCopyWithImpl<_$OffsiteHistoryStateImpl>(
          this, _$identity);
}

abstract class _OffsiteHistoryState extends OffsiteHistoryState {
  const factory _OffsiteHistoryState(
      {final AsyncValue<List<OffsiteRequestDetail>> requests,
      final TimeCorrectionStatus? filter,
      final Set<String> cancellingIds}) = _$OffsiteHistoryStateImpl;
  const _OffsiteHistoryState._() : super._();

  @override
  AsyncValue<List<OffsiteRequestDetail>> get requests;
  @override
  TimeCorrectionStatus? get filter;
  @override
  Set<String> get cancellingIds;
  @override
  @JsonKey(ignore: true)
  _$$OffsiteHistoryStateImplCopyWith<_$OffsiteHistoryStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
