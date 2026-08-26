// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leave_approvals_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$LeaveApprovalsState {
  AsyncValue<List<LeaveApproval>> get pending =>
      throw _privateConstructorUsedError;
  AsyncValue<List<LeaveApproval>> get history =>
      throw _privateConstructorUsedError;
  Set<String> get decidingIds => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $LeaveApprovalsStateCopyWith<LeaveApprovalsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LeaveApprovalsStateCopyWith<$Res> {
  factory $LeaveApprovalsStateCopyWith(
          LeaveApprovalsState value, $Res Function(LeaveApprovalsState) then) =
      _$LeaveApprovalsStateCopyWithImpl<$Res, LeaveApprovalsState>;
  @useResult
  $Res call(
      {AsyncValue<List<LeaveApproval>> pending,
      AsyncValue<List<LeaveApproval>> history,
      Set<String> decidingIds});
}

/// @nodoc
class _$LeaveApprovalsStateCopyWithImpl<$Res, $Val extends LeaveApprovalsState>
    implements $LeaveApprovalsStateCopyWith<$Res> {
  _$LeaveApprovalsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pending = null,
    Object? history = null,
    Object? decidingIds = null,
  }) {
    return _then(_value.copyWith(
      pending: null == pending
          ? _value.pending
          : pending // ignore: cast_nullable_to_non_nullable
              as AsyncValue<List<LeaveApproval>>,
      history: null == history
          ? _value.history
          : history // ignore: cast_nullable_to_non_nullable
              as AsyncValue<List<LeaveApproval>>,
      decidingIds: null == decidingIds
          ? _value.decidingIds
          : decidingIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LeaveApprovalsStateImplCopyWith<$Res>
    implements $LeaveApprovalsStateCopyWith<$Res> {
  factory _$$LeaveApprovalsStateImplCopyWith(_$LeaveApprovalsStateImpl value,
          $Res Function(_$LeaveApprovalsStateImpl) then) =
      __$$LeaveApprovalsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {AsyncValue<List<LeaveApproval>> pending,
      AsyncValue<List<LeaveApproval>> history,
      Set<String> decidingIds});
}

/// @nodoc
class __$$LeaveApprovalsStateImplCopyWithImpl<$Res>
    extends _$LeaveApprovalsStateCopyWithImpl<$Res, _$LeaveApprovalsStateImpl>
    implements _$$LeaveApprovalsStateImplCopyWith<$Res> {
  __$$LeaveApprovalsStateImplCopyWithImpl(_$LeaveApprovalsStateImpl _value,
      $Res Function(_$LeaveApprovalsStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pending = null,
    Object? history = null,
    Object? decidingIds = null,
  }) {
    return _then(_$LeaveApprovalsStateImpl(
      pending: null == pending
          ? _value.pending
          : pending // ignore: cast_nullable_to_non_nullable
              as AsyncValue<List<LeaveApproval>>,
      history: null == history
          ? _value.history
          : history // ignore: cast_nullable_to_non_nullable
              as AsyncValue<List<LeaveApproval>>,
      decidingIds: null == decidingIds
          ? _value._decidingIds
          : decidingIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ));
  }
}

/// @nodoc

class _$LeaveApprovalsStateImpl implements _LeaveApprovalsState {
  const _$LeaveApprovalsStateImpl(
      {this.pending = const AsyncValue<List<LeaveApproval>>.loading(),
      this.history = const AsyncValue<List<LeaveApproval>>.loading(),
      final Set<String> decidingIds = const <String>{}})
      : _decidingIds = decidingIds;

  @override
  @JsonKey()
  final AsyncValue<List<LeaveApproval>> pending;
  @override
  @JsonKey()
  final AsyncValue<List<LeaveApproval>> history;
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
    return 'LeaveApprovalsState(pending: $pending, history: $history, decidingIds: $decidingIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeaveApprovalsStateImpl &&
            (identical(other.pending, pending) || other.pending == pending) &&
            (identical(other.history, history) || other.history == history) &&
            const DeepCollectionEquality()
                .equals(other._decidingIds, _decidingIds));
  }

  @override
  int get hashCode => Object.hash(runtimeType, pending, history,
      const DeepCollectionEquality().hash(_decidingIds));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LeaveApprovalsStateImplCopyWith<_$LeaveApprovalsStateImpl> get copyWith =>
      __$$LeaveApprovalsStateImplCopyWithImpl<_$LeaveApprovalsStateImpl>(
          this, _$identity);
}

abstract class _LeaveApprovalsState implements LeaveApprovalsState {
  const factory _LeaveApprovalsState(
      {final AsyncValue<List<LeaveApproval>> pending,
      final AsyncValue<List<LeaveApproval>> history,
      final Set<String> decidingIds}) = _$LeaveApprovalsStateImpl;

  @override
  AsyncValue<List<LeaveApproval>> get pending;
  @override
  AsyncValue<List<LeaveApproval>> get history;
  @override
  Set<String> get decidingIds;
  @override
  @JsonKey(ignore: true)
  _$$LeaveApprovalsStateImplCopyWith<_$LeaveApprovalsStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
