// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offsite_approvals_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$OffsiteApprovalsState {
  AsyncValue<Map<TimeCorrectionStatus, List<OffsiteRequestDetail>>>
      get requests => throw _privateConstructorUsedError;
  TimeCorrectionStatus get filter => throw _privateConstructorUsedError;
  String get query => throw _privateConstructorUsedError;
  Set<String> get decidingIds => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $OffsiteApprovalsStateCopyWith<OffsiteApprovalsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OffsiteApprovalsStateCopyWith<$Res> {
  factory $OffsiteApprovalsStateCopyWith(OffsiteApprovalsState value,
          $Res Function(OffsiteApprovalsState) then) =
      _$OffsiteApprovalsStateCopyWithImpl<$Res, OffsiteApprovalsState>;
  @useResult
  $Res call(
      {AsyncValue<Map<TimeCorrectionStatus, List<OffsiteRequestDetail>>>
          requests,
      TimeCorrectionStatus filter,
      String query,
      Set<String> decidingIds});
}

/// @nodoc
class _$OffsiteApprovalsStateCopyWithImpl<$Res,
        $Val extends OffsiteApprovalsState>
    implements $OffsiteApprovalsStateCopyWith<$Res> {
  _$OffsiteApprovalsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requests = null,
    Object? filter = null,
    Object? query = null,
    Object? decidingIds = null,
  }) {
    return _then(_value.copyWith(
      requests: null == requests
          ? _value.requests
          : requests // ignore: cast_nullable_to_non_nullable
              as AsyncValue<
                  Map<TimeCorrectionStatus, List<OffsiteRequestDetail>>>,
      filter: null == filter
          ? _value.filter
          : filter // ignore: cast_nullable_to_non_nullable
              as TimeCorrectionStatus,
      query: null == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      decidingIds: null == decidingIds
          ? _value.decidingIds
          : decidingIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OffsiteApprovalsStateImplCopyWith<$Res>
    implements $OffsiteApprovalsStateCopyWith<$Res> {
  factory _$$OffsiteApprovalsStateImplCopyWith(
          _$OffsiteApprovalsStateImpl value,
          $Res Function(_$OffsiteApprovalsStateImpl) then) =
      __$$OffsiteApprovalsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {AsyncValue<Map<TimeCorrectionStatus, List<OffsiteRequestDetail>>>
          requests,
      TimeCorrectionStatus filter,
      String query,
      Set<String> decidingIds});
}

/// @nodoc
class __$$OffsiteApprovalsStateImplCopyWithImpl<$Res>
    extends _$OffsiteApprovalsStateCopyWithImpl<$Res,
        _$OffsiteApprovalsStateImpl>
    implements _$$OffsiteApprovalsStateImplCopyWith<$Res> {
  __$$OffsiteApprovalsStateImplCopyWithImpl(_$OffsiteApprovalsStateImpl _value,
      $Res Function(_$OffsiteApprovalsStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requests = null,
    Object? filter = null,
    Object? query = null,
    Object? decidingIds = null,
  }) {
    return _then(_$OffsiteApprovalsStateImpl(
      requests: null == requests
          ? _value.requests
          : requests // ignore: cast_nullable_to_non_nullable
              as AsyncValue<
                  Map<TimeCorrectionStatus, List<OffsiteRequestDetail>>>,
      filter: null == filter
          ? _value.filter
          : filter // ignore: cast_nullable_to_non_nullable
              as TimeCorrectionStatus,
      query: null == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      decidingIds: null == decidingIds
          ? _value._decidingIds
          : decidingIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ));
  }
}

/// @nodoc

class _$OffsiteApprovalsStateImpl extends _OffsiteApprovalsState {
  const _$OffsiteApprovalsStateImpl(
      {this.requests = const AsyncValue<
          Map<TimeCorrectionStatus, List<OffsiteRequestDetail>>>.loading(),
      this.filter = TimeCorrectionStatus.pending,
      this.query = '',
      final Set<String> decidingIds = const <String>{}})
      : _decidingIds = decidingIds,
        super._();

  @override
  @JsonKey()
  final AsyncValue<Map<TimeCorrectionStatus, List<OffsiteRequestDetail>>>
      requests;
  @override
  @JsonKey()
  final TimeCorrectionStatus filter;
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
    return 'OffsiteApprovalsState(requests: $requests, filter: $filter, query: $query, decidingIds: $decidingIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OffsiteApprovalsStateImpl &&
            (identical(other.requests, requests) ||
                other.requests == requests) &&
            (identical(other.filter, filter) || other.filter == filter) &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality()
                .equals(other._decidingIds, _decidingIds));
  }

  @override
  int get hashCode => Object.hash(runtimeType, requests, filter, query,
      const DeepCollectionEquality().hash(_decidingIds));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OffsiteApprovalsStateImplCopyWith<_$OffsiteApprovalsStateImpl>
      get copyWith => __$$OffsiteApprovalsStateImplCopyWithImpl<
          _$OffsiteApprovalsStateImpl>(this, _$identity);
}

abstract class _OffsiteApprovalsState extends OffsiteApprovalsState {
  const factory _OffsiteApprovalsState(
      {final AsyncValue<Map<TimeCorrectionStatus, List<OffsiteRequestDetail>>>
          requests,
      final TimeCorrectionStatus filter,
      final String query,
      final Set<String> decidingIds}) = _$OffsiteApprovalsStateImpl;
  const _OffsiteApprovalsState._() : super._();

  @override
  AsyncValue<Map<TimeCorrectionStatus, List<OffsiteRequestDetail>>>
      get requests;
  @override
  TimeCorrectionStatus get filter;
  @override
  String get query;
  @override
  Set<String> get decidingIds;
  @override
  @JsonKey(ignore: true)
  _$$OffsiteApprovalsStateImplCopyWith<_$OffsiteApprovalsStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
