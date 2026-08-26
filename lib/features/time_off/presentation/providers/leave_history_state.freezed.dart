// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leave_history_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$LeaveHistoryState {
  /// `null` means "all categories".
  LeaveCategory? get category => throw _privateConstructorUsedError;
  DateTime get from => throw _privateConstructorUsedError;
  DateTime get to => throw _privateConstructorUsedError;
  AsyncValue<List<LeaveRequest>> get requests =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $LeaveHistoryStateCopyWith<LeaveHistoryState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LeaveHistoryStateCopyWith<$Res> {
  factory $LeaveHistoryStateCopyWith(
          LeaveHistoryState value, $Res Function(LeaveHistoryState) then) =
      _$LeaveHistoryStateCopyWithImpl<$Res, LeaveHistoryState>;
  @useResult
  $Res call(
      {LeaveCategory? category,
      DateTime from,
      DateTime to,
      AsyncValue<List<LeaveRequest>> requests});
}

/// @nodoc
class _$LeaveHistoryStateCopyWithImpl<$Res, $Val extends LeaveHistoryState>
    implements $LeaveHistoryStateCopyWith<$Res> {
  _$LeaveHistoryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = freezed,
    Object? from = null,
    Object? to = null,
    Object? requests = null,
  }) {
    return _then(_value.copyWith(
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as LeaveCategory?,
      from: null == from
          ? _value.from
          : from // ignore: cast_nullable_to_non_nullable
              as DateTime,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as DateTime,
      requests: null == requests
          ? _value.requests
          : requests // ignore: cast_nullable_to_non_nullable
              as AsyncValue<List<LeaveRequest>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LeaveHistoryStateImplCopyWith<$Res>
    implements $LeaveHistoryStateCopyWith<$Res> {
  factory _$$LeaveHistoryStateImplCopyWith(_$LeaveHistoryStateImpl value,
          $Res Function(_$LeaveHistoryStateImpl) then) =
      __$$LeaveHistoryStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {LeaveCategory? category,
      DateTime from,
      DateTime to,
      AsyncValue<List<LeaveRequest>> requests});
}

/// @nodoc
class __$$LeaveHistoryStateImplCopyWithImpl<$Res>
    extends _$LeaveHistoryStateCopyWithImpl<$Res, _$LeaveHistoryStateImpl>
    implements _$$LeaveHistoryStateImplCopyWith<$Res> {
  __$$LeaveHistoryStateImplCopyWithImpl(_$LeaveHistoryStateImpl _value,
      $Res Function(_$LeaveHistoryStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = freezed,
    Object? from = null,
    Object? to = null,
    Object? requests = null,
  }) {
    return _then(_$LeaveHistoryStateImpl(
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as LeaveCategory?,
      from: null == from
          ? _value.from
          : from // ignore: cast_nullable_to_non_nullable
              as DateTime,
      to: null == to
          ? _value.to
          : to // ignore: cast_nullable_to_non_nullable
              as DateTime,
      requests: null == requests
          ? _value.requests
          : requests // ignore: cast_nullable_to_non_nullable
              as AsyncValue<List<LeaveRequest>>,
    ));
  }
}

/// @nodoc

class _$LeaveHistoryStateImpl implements _LeaveHistoryState {
  const _$LeaveHistoryStateImpl(
      {this.category,
      required this.from,
      required this.to,
      this.requests = const AsyncValue<List<LeaveRequest>>.loading()});

  /// `null` means "all categories".
  @override
  final LeaveCategory? category;
  @override
  final DateTime from;
  @override
  final DateTime to;
  @override
  @JsonKey()
  final AsyncValue<List<LeaveRequest>> requests;

  @override
  String toString() {
    return 'LeaveHistoryState(category: $category, from: $from, to: $to, requests: $requests)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeaveHistoryStateImpl &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.from, from) || other.from == from) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.requests, requests) ||
                other.requests == requests));
  }

  @override
  int get hashCode => Object.hash(runtimeType, category, from, to, requests);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LeaveHistoryStateImplCopyWith<_$LeaveHistoryStateImpl> get copyWith =>
      __$$LeaveHistoryStateImplCopyWithImpl<_$LeaveHistoryStateImpl>(
          this, _$identity);
}

abstract class _LeaveHistoryState implements LeaveHistoryState {
  const factory _LeaveHistoryState(
      {final LeaveCategory? category,
      required final DateTime from,
      required final DateTime to,
      final AsyncValue<List<LeaveRequest>> requests}) = _$LeaveHistoryStateImpl;

  @override

  /// `null` means "all categories".
  LeaveCategory? get category;
  @override
  DateTime get from;
  @override
  DateTime get to;
  @override
  AsyncValue<List<LeaveRequest>> get requests;
  @override
  @JsonKey(ignore: true)
  _$$LeaveHistoryStateImplCopyWith<_$LeaveHistoryStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
