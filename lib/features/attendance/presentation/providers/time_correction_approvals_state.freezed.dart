// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'time_correction_approvals_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TimeCorrectionApprovalsState {
  AsyncValue<List<TimeCorrectionDetail>> get requests =>
      throw _privateConstructorUsedError;
  TimeCorrectionStatus? get filter => throw _privateConstructorUsedError;
  String get query => throw _privateConstructorUsedError;
  Set<String> get decidingIds => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TimeCorrectionApprovalsStateCopyWith<TimeCorrectionApprovalsState>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimeCorrectionApprovalsStateCopyWith<$Res> {
  factory $TimeCorrectionApprovalsStateCopyWith(
    TimeCorrectionApprovalsState value,
    $Res Function(TimeCorrectionApprovalsState) then,
  ) =
      _$TimeCorrectionApprovalsStateCopyWithImpl<
        $Res,
        TimeCorrectionApprovalsState
      >;
  @useResult
  $Res call({
    AsyncValue<List<TimeCorrectionDetail>> requests,
    TimeCorrectionStatus? filter,
    String query,
    Set<String> decidingIds,
  });
}

/// @nodoc
class _$TimeCorrectionApprovalsStateCopyWithImpl<
  $Res,
  $Val extends TimeCorrectionApprovalsState
>
    implements $TimeCorrectionApprovalsStateCopyWith<$Res> {
  _$TimeCorrectionApprovalsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requests = null,
    Object? filter = freezed,
    Object? query = null,
    Object? decidingIds = null,
  }) {
    return _then(
      _value.copyWith(
            requests: null == requests
                ? _value.requests
                : requests // ignore: cast_nullable_to_non_nullable
                      as AsyncValue<List<TimeCorrectionDetail>>,
            filter: freezed == filter
                ? _value.filter
                : filter // ignore: cast_nullable_to_non_nullable
                      as TimeCorrectionStatus?,
            query: null == query
                ? _value.query
                : query // ignore: cast_nullable_to_non_nullable
                      as String,
            decidingIds: null == decidingIds
                ? _value.decidingIds
                : decidingIds // ignore: cast_nullable_to_non_nullable
                      as Set<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TimeCorrectionApprovalsStateImplCopyWith<$Res>
    implements $TimeCorrectionApprovalsStateCopyWith<$Res> {
  factory _$$TimeCorrectionApprovalsStateImplCopyWith(
    _$TimeCorrectionApprovalsStateImpl value,
    $Res Function(_$TimeCorrectionApprovalsStateImpl) then,
  ) = __$$TimeCorrectionApprovalsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    AsyncValue<List<TimeCorrectionDetail>> requests,
    TimeCorrectionStatus? filter,
    String query,
    Set<String> decidingIds,
  });
}

/// @nodoc
class __$$TimeCorrectionApprovalsStateImplCopyWithImpl<$Res>
    extends
        _$TimeCorrectionApprovalsStateCopyWithImpl<
          $Res,
          _$TimeCorrectionApprovalsStateImpl
        >
    implements _$$TimeCorrectionApprovalsStateImplCopyWith<$Res> {
  __$$TimeCorrectionApprovalsStateImplCopyWithImpl(
    _$TimeCorrectionApprovalsStateImpl _value,
    $Res Function(_$TimeCorrectionApprovalsStateImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requests = null,
    Object? filter = freezed,
    Object? query = null,
    Object? decidingIds = null,
  }) {
    return _then(
      _$TimeCorrectionApprovalsStateImpl(
        requests: null == requests
            ? _value.requests
            : requests // ignore: cast_nullable_to_non_nullable
                  as AsyncValue<List<TimeCorrectionDetail>>,
        filter: freezed == filter
            ? _value.filter
            : filter // ignore: cast_nullable_to_non_nullable
                  as TimeCorrectionStatus?,
        query: null == query
            ? _value.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
        decidingIds: null == decidingIds
            ? _value._decidingIds
            : decidingIds // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
      ),
    );
  }
}

/// @nodoc

class _$TimeCorrectionApprovalsStateImpl extends _TimeCorrectionApprovalsState {
  const _$TimeCorrectionApprovalsStateImpl({
    this.requests = const AsyncValue<List<TimeCorrectionDetail>>.loading(),
    this.filter,
    this.query = '',
    final Set<String> decidingIds = const <String>{},
  }) : _decidingIds = decidingIds,
       super._();

  @override
  @JsonKey()
  final AsyncValue<List<TimeCorrectionDetail>> requests;
  @override
  final TimeCorrectionStatus? filter;
  @override
  @JsonKey()
  final String query;
  final Set<String> _decidingIds;
  @override
  @JsonKey()
  Set<String> get decidingIds {
    if (_decidingIds is EqualUnmodifiableSetView) return _decidingIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_decidingIds);
  }

  @override
  String toString() {
    return 'TimeCorrectionApprovalsState(requests: $requests, filter: $filter, query: $query, decidingIds: $decidingIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimeCorrectionApprovalsStateImpl &&
            (identical(other.requests, requests) ||
                other.requests == requests) &&
            (identical(other.filter, filter) || other.filter == filter) &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality().equals(
              other._decidingIds,
              _decidingIds,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    requests,
    filter,
    query,
    const DeepCollectionEquality().hash(_decidingIds),
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TimeCorrectionApprovalsStateImplCopyWith<
    _$TimeCorrectionApprovalsStateImpl
  >
  get copyWith =>
      __$$TimeCorrectionApprovalsStateImplCopyWithImpl<
        _$TimeCorrectionApprovalsStateImpl
      >(this, _$identity);
}

abstract class _TimeCorrectionApprovalsState
    extends TimeCorrectionApprovalsState {
  const factory _TimeCorrectionApprovalsState({
    final AsyncValue<List<TimeCorrectionDetail>> requests,
    final TimeCorrectionStatus? filter,
    final String query,
    final Set<String> decidingIds,
  }) = _$TimeCorrectionApprovalsStateImpl;
  const _TimeCorrectionApprovalsState._() : super._();

  @override
  AsyncValue<List<TimeCorrectionDetail>> get requests;
  @override
  TimeCorrectionStatus? get filter;
  @override
  String get query;
  @override
  Set<String> get decidingIds;
  @override
  @JsonKey(ignore: true)
  _$$TimeCorrectionApprovalsStateImplCopyWith<
    _$TimeCorrectionApprovalsStateImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}
