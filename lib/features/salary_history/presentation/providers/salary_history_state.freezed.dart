// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'salary_history_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SalaryHistoryState {
  int get year => throw _privateConstructorUsedError;
  SalaryHistoryFilter get filter => throw _privateConstructorUsedError;
  AsyncValue<List<Payslip>> get payslips => throw _privateConstructorUsedError;
  Set<int> get expandedIndexes => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SalaryHistoryStateCopyWith<SalaryHistoryState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SalaryHistoryStateCopyWith<$Res> {
  factory $SalaryHistoryStateCopyWith(
          SalaryHistoryState value, $Res Function(SalaryHistoryState) then) =
      _$SalaryHistoryStateCopyWithImpl<$Res, SalaryHistoryState>;
  @useResult
  $Res call(
      {int year,
      SalaryHistoryFilter filter,
      AsyncValue<List<Payslip>> payslips,
      Set<int> expandedIndexes});
}

/// @nodoc
class _$SalaryHistoryStateCopyWithImpl<$Res, $Val extends SalaryHistoryState>
    implements $SalaryHistoryStateCopyWith<$Res> {
  _$SalaryHistoryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? filter = null,
    Object? payslips = null,
    Object? expandedIndexes = null,
  }) {
    return _then(_value.copyWith(
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      filter: null == filter
          ? _value.filter
          : filter // ignore: cast_nullable_to_non_nullable
              as SalaryHistoryFilter,
      payslips: null == payslips
          ? _value.payslips
          : payslips // ignore: cast_nullable_to_non_nullable
              as AsyncValue<List<Payslip>>,
      expandedIndexes: null == expandedIndexes
          ? _value.expandedIndexes
          : expandedIndexes // ignore: cast_nullable_to_non_nullable
              as Set<int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SalaryHistoryStateImplCopyWith<$Res>
    implements $SalaryHistoryStateCopyWith<$Res> {
  factory _$$SalaryHistoryStateImplCopyWith(_$SalaryHistoryStateImpl value,
          $Res Function(_$SalaryHistoryStateImpl) then) =
      __$$SalaryHistoryStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int year,
      SalaryHistoryFilter filter,
      AsyncValue<List<Payslip>> payslips,
      Set<int> expandedIndexes});
}

/// @nodoc
class __$$SalaryHistoryStateImplCopyWithImpl<$Res>
    extends _$SalaryHistoryStateCopyWithImpl<$Res, _$SalaryHistoryStateImpl>
    implements _$$SalaryHistoryStateImplCopyWith<$Res> {
  __$$SalaryHistoryStateImplCopyWithImpl(_$SalaryHistoryStateImpl _value,
      $Res Function(_$SalaryHistoryStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? filter = null,
    Object? payslips = null,
    Object? expandedIndexes = null,
  }) {
    return _then(_$SalaryHistoryStateImpl(
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      filter: null == filter
          ? _value.filter
          : filter // ignore: cast_nullable_to_non_nullable
              as SalaryHistoryFilter,
      payslips: null == payslips
          ? _value.payslips
          : payslips // ignore: cast_nullable_to_non_nullable
              as AsyncValue<List<Payslip>>,
      expandedIndexes: null == expandedIndexes
          ? _value._expandedIndexes
          : expandedIndexes // ignore: cast_nullable_to_non_nullable
              as Set<int>,
    ));
  }
}

/// @nodoc

class _$SalaryHistoryStateImpl extends _SalaryHistoryState {
  const _$SalaryHistoryStateImpl(
      {required this.year,
      this.filter = SalaryHistoryFilter.all,
      this.payslips = const AsyncValue<List<Payslip>>.loading(),
      final Set<int> expandedIndexes = const <int>{}})
      : _expandedIndexes = expandedIndexes,
        super._();

  @override
  final int year;
  @override
  @JsonKey()
  final SalaryHistoryFilter filter;
  @override
  @JsonKey()
  final AsyncValue<List<Payslip>> payslips;
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
    return 'SalaryHistoryState(year: $year, filter: $filter, payslips: $payslips, expandedIndexes: $expandedIndexes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SalaryHistoryStateImpl &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.filter, filter) || other.filter == filter) &&
            (identical(other.payslips, payslips) ||
                other.payslips == payslips) &&
            const DeepCollectionEquality()
                .equals(other._expandedIndexes, _expandedIndexes));
  }

  @override
  int get hashCode => Object.hash(runtimeType, year, filter, payslips,
      const DeepCollectionEquality().hash(_expandedIndexes));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SalaryHistoryStateImplCopyWith<_$SalaryHistoryStateImpl> get copyWith =>
      __$$SalaryHistoryStateImplCopyWithImpl<_$SalaryHistoryStateImpl>(
          this, _$identity);
}

abstract class _SalaryHistoryState extends SalaryHistoryState {
  const factory _SalaryHistoryState(
      {required final int year,
      final SalaryHistoryFilter filter,
      final AsyncValue<List<Payslip>> payslips,
      final Set<int> expandedIndexes}) = _$SalaryHistoryStateImpl;
  const _SalaryHistoryState._() : super._();

  @override
  int get year;
  @override
  SalaryHistoryFilter get filter;
  @override
  AsyncValue<List<Payslip>> get payslips;
  @override
  Set<int> get expandedIndexes;
  @override
  @JsonKey(ignore: true)
  _$$SalaryHistoryStateImplCopyWith<_$SalaryHistoryStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
