// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_history_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AttendanceHistoryState {
  /// The 1st of the viewed month, local time.
  DateTime get month => throw _privateConstructorUsedError;
  AsyncValue<List<AttendanceDay>> get records =>
      throw _privateConstructorUsedError;
  AsyncValue<AttendanceSummary> get summary =>
      throw _privateConstructorUsedError;
  Set<int> get expandedIndexes => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AttendanceHistoryStateCopyWith<AttendanceHistoryState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttendanceHistoryStateCopyWith<$Res> {
  factory $AttendanceHistoryStateCopyWith(AttendanceHistoryState value,
          $Res Function(AttendanceHistoryState) then) =
      _$AttendanceHistoryStateCopyWithImpl<$Res, AttendanceHistoryState>;
  @useResult
  $Res call(
      {DateTime month,
      AsyncValue<List<AttendanceDay>> records,
      AsyncValue<AttendanceSummary> summary,
      Set<int> expandedIndexes});
}

/// @nodoc
class _$AttendanceHistoryStateCopyWithImpl<$Res,
        $Val extends AttendanceHistoryState>
    implements $AttendanceHistoryStateCopyWith<$Res> {
  _$AttendanceHistoryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? month = null,
    Object? records = null,
    Object? summary = null,
    Object? expandedIndexes = null,
  }) {
    return _then(_value.copyWith(
      month: null == month
          ? _value.month
          : month // ignore: cast_nullable_to_non_nullable
              as DateTime,
      records: null == records
          ? _value.records
          : records // ignore: cast_nullable_to_non_nullable
              as AsyncValue<List<AttendanceDay>>,
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as AsyncValue<AttendanceSummary>,
      expandedIndexes: null == expandedIndexes
          ? _value.expandedIndexes
          : expandedIndexes // ignore: cast_nullable_to_non_nullable
              as Set<int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AttendanceHistoryStateImplCopyWith<$Res>
    implements $AttendanceHistoryStateCopyWith<$Res> {
  factory _$$AttendanceHistoryStateImplCopyWith(
          _$AttendanceHistoryStateImpl value,
          $Res Function(_$AttendanceHistoryStateImpl) then) =
      __$$AttendanceHistoryStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime month,
      AsyncValue<List<AttendanceDay>> records,
      AsyncValue<AttendanceSummary> summary,
      Set<int> expandedIndexes});
}

/// @nodoc
class __$$AttendanceHistoryStateImplCopyWithImpl<$Res>
    extends _$AttendanceHistoryStateCopyWithImpl<$Res,
        _$AttendanceHistoryStateImpl>
    implements _$$AttendanceHistoryStateImplCopyWith<$Res> {
  __$$AttendanceHistoryStateImplCopyWithImpl(
      _$AttendanceHistoryStateImpl _value,
      $Res Function(_$AttendanceHistoryStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? month = null,
    Object? records = null,
    Object? summary = null,
    Object? expandedIndexes = null,
  }) {
    return _then(_$AttendanceHistoryStateImpl(
      month: null == month
          ? _value.month
          : month // ignore: cast_nullable_to_non_nullable
              as DateTime,
      records: null == records
          ? _value.records
          : records // ignore: cast_nullable_to_non_nullable
              as AsyncValue<List<AttendanceDay>>,
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as AsyncValue<AttendanceSummary>,
      expandedIndexes: null == expandedIndexes
          ? _value._expandedIndexes
          : expandedIndexes // ignore: cast_nullable_to_non_nullable
              as Set<int>,
    ));
  }
}

/// @nodoc

class _$AttendanceHistoryStateImpl extends _AttendanceHistoryState {
  const _$AttendanceHistoryStateImpl(
      {required this.month,
      this.records = const AsyncValue<List<AttendanceDay>>.loading(),
      this.summary = const AsyncValue<AttendanceSummary>.loading(),
      final Set<int> expandedIndexes = const <int>{}})
      : _expandedIndexes = expandedIndexes,
        super._();

  /// The 1st of the viewed month, local time.
  @override
  final DateTime month;
  @override
  @JsonKey()
  final AsyncValue<List<AttendanceDay>> records;
  @override
  @JsonKey()
  final AsyncValue<AttendanceSummary> summary;
  final Set<int> _expandedIndexes;
  @override
  @JsonKey()
  Set<int> get expandedIndexes {
    if (_expandedIndexes is EqualUnmodifiableSetView) return _expandedIndexes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_expandedIndexes);
  }

  @override
  String toString() {
    return 'AttendanceHistoryState(month: $month, records: $records, summary: $summary, expandedIndexes: $expandedIndexes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttendanceHistoryStateImpl &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.records, records) || other.records == records) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            const DeepCollectionEquality()
                .equals(other._expandedIndexes, _expandedIndexes));
  }

  @override
  int get hashCode => Object.hash(runtimeType, month, records, summary,
      const DeepCollectionEquality().hash(_expandedIndexes));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AttendanceHistoryStateImplCopyWith<_$AttendanceHistoryStateImpl>
      get copyWith => __$$AttendanceHistoryStateImplCopyWithImpl<
          _$AttendanceHistoryStateImpl>(this, _$identity);
}

abstract class _AttendanceHistoryState extends AttendanceHistoryState {
  const factory _AttendanceHistoryState(
      {required final DateTime month,
      final AsyncValue<List<AttendanceDay>> records,
      final AsyncValue<AttendanceSummary> summary,
      final Set<int> expandedIndexes}) = _$AttendanceHistoryStateImpl;
  const _AttendanceHistoryState._() : super._();

  @override

  /// The 1st of the viewed month, local time.
  DateTime get month;
  @override
  AsyncValue<List<AttendanceDay>> get records;
  @override
  AsyncValue<AttendanceSummary> get summary;
  @override
  Set<int> get expandedIndexes;
  @override
  @JsonKey(ignore: true)
  _$$AttendanceHistoryStateImplCopyWith<_$AttendanceHistoryStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
