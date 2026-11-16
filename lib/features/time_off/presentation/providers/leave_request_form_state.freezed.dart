// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leave_request_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LeaveRequestFormState {
  /// Non-null once [LeaveRequestFormNotifier.seed] has run — i.e. edit mode.
  String? get editingRequestId => throw _privateConstructorUsedError;
  String? get leaveTypeId => throw _privateConstructorUsedError;
  LeaveDaysMode get mode => throw _privateConstructorUsedError;

  /// Separate-days mode: the days picked, sorted.
  List<DateTime> get dates => throw _privateConstructorUsedError;

  /// Range mode: the first and the last day asked for, both included.
  DateTime? get rangeStart => throw _privateConstructorUsedError;
  DateTime? get rangeEnd => throw _privateConstructorUsedError;
  LeaveDurationType get durationType => throw _privateConstructorUsedError;
  DateTime? get returnToWorkOverride => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;

  /// The company's days off, or null while they are not known (still
  /// loading, or the load failed). Kept here by the notifier so the counts
  /// below need nothing handed to them.
  CompanyDaysOff? get daysOff => throw _privateConstructorUsedError;

  /// Edit mode only: the leave type the request had when it was opened. The
  /// form keeps offering it even after HR switched it off.
  String? get originalLeaveTypeId => throw _privateConstructorUsedError;

  /// Edit mode only: how many days the request asked for when it was
  /// opened. The balance is checked on an edit only when the count grows
  /// past this, as the server does.
  double? get originalTotalDays => throw _privateConstructorUsedError;

  /// Edit mode only: the year the request's days were charged to when it
  /// was opened (the year of its first leave day).
  int? get originalBalanceYear => throw _privateConstructorUsedError;
  AsyncValue<LeaveRequest?> get submission =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $LeaveRequestFormStateCopyWith<LeaveRequestFormState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LeaveRequestFormStateCopyWith<$Res> {
  factory $LeaveRequestFormStateCopyWith(
    LeaveRequestFormState value,
    $Res Function(LeaveRequestFormState) then,
  ) = _$LeaveRequestFormStateCopyWithImpl<$Res, LeaveRequestFormState>;
  @useResult
  $Res call({
    String? editingRequestId,
    String? leaveTypeId,
    LeaveDaysMode mode,
    List<DateTime> dates,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    LeaveDurationType durationType,
    DateTime? returnToWorkOverride,
    String reason,
    CompanyDaysOff? daysOff,
    String? originalLeaveTypeId,
    double? originalTotalDays,
    int? originalBalanceYear,
    AsyncValue<LeaveRequest?> submission,
  });
}

/// @nodoc
class _$LeaveRequestFormStateCopyWithImpl<
  $Res,
  $Val extends LeaveRequestFormState
>
    implements $LeaveRequestFormStateCopyWith<$Res> {
  _$LeaveRequestFormStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? editingRequestId = freezed,
    Object? leaveTypeId = freezed,
    Object? mode = null,
    Object? dates = null,
    Object? rangeStart = freezed,
    Object? rangeEnd = freezed,
    Object? durationType = null,
    Object? returnToWorkOverride = freezed,
    Object? reason = null,
    Object? daysOff = freezed,
    Object? originalLeaveTypeId = freezed,
    Object? originalTotalDays = freezed,
    Object? originalBalanceYear = freezed,
    Object? submission = null,
  }) {
    return _then(
      _value.copyWith(
            editingRequestId: freezed == editingRequestId
                ? _value.editingRequestId
                : editingRequestId // ignore: cast_nullable_to_non_nullable
                      as String?,
            leaveTypeId: freezed == leaveTypeId
                ? _value.leaveTypeId
                : leaveTypeId // ignore: cast_nullable_to_non_nullable
                      as String?,
            mode: null == mode
                ? _value.mode
                : mode // ignore: cast_nullable_to_non_nullable
                      as LeaveDaysMode,
            dates: null == dates
                ? _value.dates
                : dates // ignore: cast_nullable_to_non_nullable
                      as List<DateTime>,
            rangeStart: freezed == rangeStart
                ? _value.rangeStart
                : rangeStart // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            rangeEnd: freezed == rangeEnd
                ? _value.rangeEnd
                : rangeEnd // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            durationType: null == durationType
                ? _value.durationType
                : durationType // ignore: cast_nullable_to_non_nullable
                      as LeaveDurationType,
            returnToWorkOverride: freezed == returnToWorkOverride
                ? _value.returnToWorkOverride
                : returnToWorkOverride // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
            daysOff: freezed == daysOff
                ? _value.daysOff
                : daysOff // ignore: cast_nullable_to_non_nullable
                      as CompanyDaysOff?,
            originalLeaveTypeId: freezed == originalLeaveTypeId
                ? _value.originalLeaveTypeId
                : originalLeaveTypeId // ignore: cast_nullable_to_non_nullable
                      as String?,
            originalTotalDays: freezed == originalTotalDays
                ? _value.originalTotalDays
                : originalTotalDays // ignore: cast_nullable_to_non_nullable
                      as double?,
            originalBalanceYear: freezed == originalBalanceYear
                ? _value.originalBalanceYear
                : originalBalanceYear // ignore: cast_nullable_to_non_nullable
                      as int?,
            submission: null == submission
                ? _value.submission
                : submission // ignore: cast_nullable_to_non_nullable
                      as AsyncValue<LeaveRequest?>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LeaveRequestFormStateImplCopyWith<$Res>
    implements $LeaveRequestFormStateCopyWith<$Res> {
  factory _$$LeaveRequestFormStateImplCopyWith(
    _$LeaveRequestFormStateImpl value,
    $Res Function(_$LeaveRequestFormStateImpl) then,
  ) = __$$LeaveRequestFormStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? editingRequestId,
    String? leaveTypeId,
    LeaveDaysMode mode,
    List<DateTime> dates,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    LeaveDurationType durationType,
    DateTime? returnToWorkOverride,
    String reason,
    CompanyDaysOff? daysOff,
    String? originalLeaveTypeId,
    double? originalTotalDays,
    int? originalBalanceYear,
    AsyncValue<LeaveRequest?> submission,
  });
}

/// @nodoc
class __$$LeaveRequestFormStateImplCopyWithImpl<$Res>
    extends
        _$LeaveRequestFormStateCopyWithImpl<$Res, _$LeaveRequestFormStateImpl>
    implements _$$LeaveRequestFormStateImplCopyWith<$Res> {
  __$$LeaveRequestFormStateImplCopyWithImpl(
    _$LeaveRequestFormStateImpl _value,
    $Res Function(_$LeaveRequestFormStateImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? editingRequestId = freezed,
    Object? leaveTypeId = freezed,
    Object? mode = null,
    Object? dates = null,
    Object? rangeStart = freezed,
    Object? rangeEnd = freezed,
    Object? durationType = null,
    Object? returnToWorkOverride = freezed,
    Object? reason = null,
    Object? daysOff = freezed,
    Object? originalLeaveTypeId = freezed,
    Object? originalTotalDays = freezed,
    Object? originalBalanceYear = freezed,
    Object? submission = null,
  }) {
    return _then(
      _$LeaveRequestFormStateImpl(
        editingRequestId: freezed == editingRequestId
            ? _value.editingRequestId
            : editingRequestId // ignore: cast_nullable_to_non_nullable
                  as String?,
        leaveTypeId: freezed == leaveTypeId
            ? _value.leaveTypeId
            : leaveTypeId // ignore: cast_nullable_to_non_nullable
                  as String?,
        mode: null == mode
            ? _value.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as LeaveDaysMode,
        dates: null == dates
            ? _value._dates
            : dates // ignore: cast_nullable_to_non_nullable
                  as List<DateTime>,
        rangeStart: freezed == rangeStart
            ? _value.rangeStart
            : rangeStart // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        rangeEnd: freezed == rangeEnd
            ? _value.rangeEnd
            : rangeEnd // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        durationType: null == durationType
            ? _value.durationType
            : durationType // ignore: cast_nullable_to_non_nullable
                  as LeaveDurationType,
        returnToWorkOverride: freezed == returnToWorkOverride
            ? _value.returnToWorkOverride
            : returnToWorkOverride // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
        daysOff: freezed == daysOff
            ? _value.daysOff
            : daysOff // ignore: cast_nullable_to_non_nullable
                  as CompanyDaysOff?,
        originalLeaveTypeId: freezed == originalLeaveTypeId
            ? _value.originalLeaveTypeId
            : originalLeaveTypeId // ignore: cast_nullable_to_non_nullable
                  as String?,
        originalTotalDays: freezed == originalTotalDays
            ? _value.originalTotalDays
            : originalTotalDays // ignore: cast_nullable_to_non_nullable
                  as double?,
        originalBalanceYear: freezed == originalBalanceYear
            ? _value.originalBalanceYear
            : originalBalanceYear // ignore: cast_nullable_to_non_nullable
                  as int?,
        submission: null == submission
            ? _value.submission
            : submission // ignore: cast_nullable_to_non_nullable
                  as AsyncValue<LeaveRequest?>,
      ),
    );
  }
}

/// @nodoc

class _$LeaveRequestFormStateImpl extends _LeaveRequestFormState {
  const _$LeaveRequestFormStateImpl({
    this.editingRequestId,
    this.leaveTypeId,
    this.mode = LeaveDaysMode.range,
    final List<DateTime> dates = const <DateTime>[],
    this.rangeStart,
    this.rangeEnd,
    this.durationType = LeaveDurationType.fullDay,
    this.returnToWorkOverride,
    this.reason = '',
    this.daysOff,
    this.originalLeaveTypeId,
    this.originalTotalDays,
    this.originalBalanceYear,
    this.submission = const AsyncValue<LeaveRequest?>.data(null),
  }) : _dates = dates,
       super._();

  /// Non-null once [LeaveRequestFormNotifier.seed] has run — i.e. edit mode.
  @override
  final String? editingRequestId;
  @override
  final String? leaveTypeId;
  @override
  @JsonKey()
  final LeaveDaysMode mode;

  /// Separate-days mode: the days picked, sorted.
  final List<DateTime> _dates;

  /// Separate-days mode: the days picked, sorted.
  @override
  @JsonKey()
  List<DateTime> get dates {
    if (_dates is EqualUnmodifiableListView) return _dates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dates);
  }

  /// Range mode: the first and the last day asked for, both included.
  @override
  final DateTime? rangeStart;
  @override
  final DateTime? rangeEnd;
  @override
  @JsonKey()
  final LeaveDurationType durationType;
  @override
  final DateTime? returnToWorkOverride;
  @override
  @JsonKey()
  final String reason;

  /// The company's days off, or null while they are not known (still
  /// loading, or the load failed). Kept here by the notifier so the counts
  /// below need nothing handed to them.
  @override
  final CompanyDaysOff? daysOff;

  /// Edit mode only: the leave type the request had when it was opened. The
  /// form keeps offering it even after HR switched it off.
  @override
  final String? originalLeaveTypeId;

  /// Edit mode only: how many days the request asked for when it was
  /// opened. The balance is checked on an edit only when the count grows
  /// past this, as the server does.
  @override
  final double? originalTotalDays;

  /// Edit mode only: the year the request's days were charged to when it
  /// was opened (the year of its first leave day).
  @override
  final int? originalBalanceYear;
  @override
  @JsonKey()
  final AsyncValue<LeaveRequest?> submission;

  @override
  String toString() {
    return 'LeaveRequestFormState(editingRequestId: $editingRequestId, leaveTypeId: $leaveTypeId, mode: $mode, dates: $dates, rangeStart: $rangeStart, rangeEnd: $rangeEnd, durationType: $durationType, returnToWorkOverride: $returnToWorkOverride, reason: $reason, daysOff: $daysOff, originalLeaveTypeId: $originalLeaveTypeId, originalTotalDays: $originalTotalDays, originalBalanceYear: $originalBalanceYear, submission: $submission)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeaveRequestFormStateImpl &&
            (identical(other.editingRequestId, editingRequestId) ||
                other.editingRequestId == editingRequestId) &&
            (identical(other.leaveTypeId, leaveTypeId) ||
                other.leaveTypeId == leaveTypeId) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            const DeepCollectionEquality().equals(other._dates, _dates) &&
            (identical(other.rangeStart, rangeStart) ||
                other.rangeStart == rangeStart) &&
            (identical(other.rangeEnd, rangeEnd) ||
                other.rangeEnd == rangeEnd) &&
            (identical(other.durationType, durationType) ||
                other.durationType == durationType) &&
            (identical(other.returnToWorkOverride, returnToWorkOverride) ||
                other.returnToWorkOverride == returnToWorkOverride) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.daysOff, daysOff) || other.daysOff == daysOff) &&
            (identical(other.originalLeaveTypeId, originalLeaveTypeId) ||
                other.originalLeaveTypeId == originalLeaveTypeId) &&
            (identical(other.originalTotalDays, originalTotalDays) ||
                other.originalTotalDays == originalTotalDays) &&
            (identical(other.originalBalanceYear, originalBalanceYear) ||
                other.originalBalanceYear == originalBalanceYear) &&
            (identical(other.submission, submission) ||
                other.submission == submission));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    editingRequestId,
    leaveTypeId,
    mode,
    const DeepCollectionEquality().hash(_dates),
    rangeStart,
    rangeEnd,
    durationType,
    returnToWorkOverride,
    reason,
    daysOff,
    originalLeaveTypeId,
    originalTotalDays,
    originalBalanceYear,
    submission,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LeaveRequestFormStateImplCopyWith<_$LeaveRequestFormStateImpl>
  get copyWith =>
      __$$LeaveRequestFormStateImplCopyWithImpl<_$LeaveRequestFormStateImpl>(
        this,
        _$identity,
      );
}

abstract class _LeaveRequestFormState extends LeaveRequestFormState {
  const factory _LeaveRequestFormState({
    final String? editingRequestId,
    final String? leaveTypeId,
    final LeaveDaysMode mode,
    final List<DateTime> dates,
    final DateTime? rangeStart,
    final DateTime? rangeEnd,
    final LeaveDurationType durationType,
    final DateTime? returnToWorkOverride,
    final String reason,
    final CompanyDaysOff? daysOff,
    final String? originalLeaveTypeId,
    final double? originalTotalDays,
    final int? originalBalanceYear,
    final AsyncValue<LeaveRequest?> submission,
  }) = _$LeaveRequestFormStateImpl;
  const _LeaveRequestFormState._() : super._();

  @override
  /// Non-null once [LeaveRequestFormNotifier.seed] has run — i.e. edit mode.
  String? get editingRequestId;
  @override
  String? get leaveTypeId;
  @override
  LeaveDaysMode get mode;
  @override
  /// Separate-days mode: the days picked, sorted.
  List<DateTime> get dates;
  @override
  /// Range mode: the first and the last day asked for, both included.
  DateTime? get rangeStart;
  @override
  DateTime? get rangeEnd;
  @override
  LeaveDurationType get durationType;
  @override
  DateTime? get returnToWorkOverride;
  @override
  String get reason;
  @override
  /// The company's days off, or null while they are not known (still
  /// loading, or the load failed). Kept here by the notifier so the counts
  /// below need nothing handed to them.
  CompanyDaysOff? get daysOff;
  @override
  /// Edit mode only: the leave type the request had when it was opened. The
  /// form keeps offering it even after HR switched it off.
  String? get originalLeaveTypeId;
  @override
  /// Edit mode only: how many days the request asked for when it was
  /// opened. The balance is checked on an edit only when the count grows
  /// past this, as the server does.
  double? get originalTotalDays;
  @override
  /// Edit mode only: the year the request's days were charged to when it
  /// was opened (the year of its first leave day).
  int? get originalBalanceYear;
  @override
  AsyncValue<LeaveRequest?> get submission;
  @override
  @JsonKey(ignore: true)
  _$$LeaveRequestFormStateImplCopyWith<_$LeaveRequestFormStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
