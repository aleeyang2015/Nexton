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
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$OffsiteApprovalsState {
  AsyncValue<PagedList<OffsiteRequestDetail>> get pending =>
      throw _privateConstructorUsedError;
  AsyncValue<PagedList<OffsiteRequestDetail>> get decided =>
      throw _privateConstructorUsedError;
  TimeCorrectionStatus get decidedFilter => throw _privateConstructorUsedError;

  /// Check-outs whose check-in was rejected or cancelled
  /// (`CHECKIN_NOT_APPROVED`): they can only be rejected, so Approve goes.
  Set<String> get rejectOnlyIds => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $OffsiteApprovalsStateCopyWith<OffsiteApprovalsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OffsiteApprovalsStateCopyWith<$Res> {
  factory $OffsiteApprovalsStateCopyWith(
    OffsiteApprovalsState value,
    $Res Function(OffsiteApprovalsState) then,
  ) = _$OffsiteApprovalsStateCopyWithImpl<$Res, OffsiteApprovalsState>;
  @useResult
  $Res call({
    AsyncValue<PagedList<OffsiteRequestDetail>> pending,
    AsyncValue<PagedList<OffsiteRequestDetail>> decided,
    TimeCorrectionStatus decidedFilter,
    Set<String> rejectOnlyIds,
  });
}

/// @nodoc
class _$OffsiteApprovalsStateCopyWithImpl<
  $Res,
  $Val extends OffsiteApprovalsState
>
    implements $OffsiteApprovalsStateCopyWith<$Res> {
  _$OffsiteApprovalsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pending = null,
    Object? decided = null,
    Object? decidedFilter = null,
    Object? rejectOnlyIds = null,
  }) {
    return _then(
      _value.copyWith(
            pending: null == pending
                ? _value.pending
                : pending // ignore: cast_nullable_to_non_nullable
                      as AsyncValue<PagedList<OffsiteRequestDetail>>,
            decided: null == decided
                ? _value.decided
                : decided // ignore: cast_nullable_to_non_nullable
                      as AsyncValue<PagedList<OffsiteRequestDetail>>,
            decidedFilter: null == decidedFilter
                ? _value.decidedFilter
                : decidedFilter // ignore: cast_nullable_to_non_nullable
                      as TimeCorrectionStatus,
            rejectOnlyIds: null == rejectOnlyIds
                ? _value.rejectOnlyIds
                : rejectOnlyIds // ignore: cast_nullable_to_non_nullable
                      as Set<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OffsiteApprovalsStateImplCopyWith<$Res>
    implements $OffsiteApprovalsStateCopyWith<$Res> {
  factory _$$OffsiteApprovalsStateImplCopyWith(
    _$OffsiteApprovalsStateImpl value,
    $Res Function(_$OffsiteApprovalsStateImpl) then,
  ) = __$$OffsiteApprovalsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    AsyncValue<PagedList<OffsiteRequestDetail>> pending,
    AsyncValue<PagedList<OffsiteRequestDetail>> decided,
    TimeCorrectionStatus decidedFilter,
    Set<String> rejectOnlyIds,
  });
}

/// @nodoc
class __$$OffsiteApprovalsStateImplCopyWithImpl<$Res>
    extends
        _$OffsiteApprovalsStateCopyWithImpl<$Res, _$OffsiteApprovalsStateImpl>
    implements _$$OffsiteApprovalsStateImplCopyWith<$Res> {
  __$$OffsiteApprovalsStateImplCopyWithImpl(
    _$OffsiteApprovalsStateImpl _value,
    $Res Function(_$OffsiteApprovalsStateImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pending = null,
    Object? decided = null,
    Object? decidedFilter = null,
    Object? rejectOnlyIds = null,
  }) {
    return _then(
      _$OffsiteApprovalsStateImpl(
        pending: null == pending
            ? _value.pending
            : pending // ignore: cast_nullable_to_non_nullable
                  as AsyncValue<PagedList<OffsiteRequestDetail>>,
        decided: null == decided
            ? _value.decided
            : decided // ignore: cast_nullable_to_non_nullable
                  as AsyncValue<PagedList<OffsiteRequestDetail>>,
        decidedFilter: null == decidedFilter
            ? _value.decidedFilter
            : decidedFilter // ignore: cast_nullable_to_non_nullable
                  as TimeCorrectionStatus,
        rejectOnlyIds: null == rejectOnlyIds
            ? _value._rejectOnlyIds
            : rejectOnlyIds // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
      ),
    );
  }
}

/// @nodoc

class _$OffsiteApprovalsStateImpl extends _OffsiteApprovalsState {
  const _$OffsiteApprovalsStateImpl({
    this.pending = const AsyncValue<PagedList<OffsiteRequestDetail>>.loading(),
    this.decided = const AsyncValue<PagedList<OffsiteRequestDetail>>.loading(),
    this.decidedFilter = TimeCorrectionStatus.approved,
    final Set<String> rejectOnlyIds = const <String>{},
  }) : _rejectOnlyIds = rejectOnlyIds,
       super._();

  @override
  @JsonKey()
  final AsyncValue<PagedList<OffsiteRequestDetail>> pending;
  @override
  @JsonKey()
  final AsyncValue<PagedList<OffsiteRequestDetail>> decided;
  @override
  @JsonKey()
  final TimeCorrectionStatus decidedFilter;

  /// Check-outs whose check-in was rejected or cancelled
  /// (`CHECKIN_NOT_APPROVED`): they can only be rejected, so Approve goes.
  final Set<String> _rejectOnlyIds;

  /// Check-outs whose check-in was rejected or cancelled
  /// (`CHECKIN_NOT_APPROVED`): they can only be rejected, so Approve goes.
  @override
  @JsonKey()
  Set<String> get rejectOnlyIds {
    if (_rejectOnlyIds is EqualUnmodifiableSetView) return _rejectOnlyIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_rejectOnlyIds);
  }

  @override
  String toString() {
    return 'OffsiteApprovalsState(pending: $pending, decided: $decided, decidedFilter: $decidedFilter, rejectOnlyIds: $rejectOnlyIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OffsiteApprovalsStateImpl &&
            (identical(other.pending, pending) || other.pending == pending) &&
            (identical(other.decided, decided) || other.decided == decided) &&
            (identical(other.decidedFilter, decidedFilter) ||
                other.decidedFilter == decidedFilter) &&
            const DeepCollectionEquality().equals(
              other._rejectOnlyIds,
              _rejectOnlyIds,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    pending,
    decided,
    decidedFilter,
    const DeepCollectionEquality().hash(_rejectOnlyIds),
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OffsiteApprovalsStateImplCopyWith<_$OffsiteApprovalsStateImpl>
  get copyWith =>
      __$$OffsiteApprovalsStateImplCopyWithImpl<_$OffsiteApprovalsStateImpl>(
        this,
        _$identity,
      );
}

abstract class _OffsiteApprovalsState extends OffsiteApprovalsState {
  const factory _OffsiteApprovalsState({
    final AsyncValue<PagedList<OffsiteRequestDetail>> pending,
    final AsyncValue<PagedList<OffsiteRequestDetail>> decided,
    final TimeCorrectionStatus decidedFilter,
    final Set<String> rejectOnlyIds,
  }) = _$OffsiteApprovalsStateImpl;
  const _OffsiteApprovalsState._() : super._();

  @override
  AsyncValue<PagedList<OffsiteRequestDetail>> get pending;
  @override
  AsyncValue<PagedList<OffsiteRequestDetail>> get decided;
  @override
  TimeCorrectionStatus get decidedFilter;
  @override
  /// Check-outs whose check-in was rejected or cancelled
  /// (`CHECKIN_NOT_APPROVED`): they can only be rejected, so Approve goes.
  Set<String> get rejectOnlyIds;
  @override
  @JsonKey(ignore: true)
  _$$OffsiteApprovalsStateImplCopyWith<_$OffsiteApprovalsStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
