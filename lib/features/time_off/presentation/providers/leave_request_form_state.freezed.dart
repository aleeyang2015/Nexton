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
  List<DateTime> get dates => throw _privateConstructorUsedError;
  LeaveDurationType get durationType => throw _privateConstructorUsedError;
  DateTime? get returnToWorkOverride => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
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
    List<DateTime> dates,
    LeaveDurationType durationType,
    DateTime? returnToWorkOverride,
    String reason,
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
    Object? dates = null,
    Object? durationType = null,
    Object? returnToWorkOverride = freezed,
    Object? reason = null,
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
            dates: null == dates
                ? _value.dates
                : dates // ignore: cast_nullable_to_non_nullable
                      as List<DateTime>,
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
    List<DateTime> dates,
    LeaveDurationType durationType,
    DateTime? returnToWorkOverride,
    String reason,
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
    Object? dates = null,
    Object? durationType = null,
    Object? returnToWorkOverride = freezed,
    Object? reason = null,
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
        dates: null == dates
            ? _value._dates
            : dates // ignore: cast_nullable_to_non_nullable
                  as List<DateTime>,
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
    final List<DateTime> dates = const <DateTime>[],
    this.durationType = LeaveDurationType.fullDay,
    this.returnToWorkOverride,
    this.reason = '',
    this.submission = const AsyncValue<LeaveRequest?>.data(null),
  }) : _dates = dates,
       super._();

  /// Non-null once [LeaveRequestFormNotifier.seed] has run — i.e. edit mode.
  @override
  final String? editingRequestId;
  @override
  final String? leaveTypeId;
  final List<DateTime> _dates;
  @override
  @JsonKey()
  List<DateTime> get dates {
    if (_dates is EqualUnmodifiableListView) return _dates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dates);
  }

  @override
  @JsonKey()
  final LeaveDurationType durationType;
  @override
  final DateTime? returnToWorkOverride;
  @override
  @JsonKey()
  final String reason;
  @override
  @JsonKey()
  final AsyncValue<LeaveRequest?> submission;

  @override
  String toString() {
    return 'LeaveRequestFormState(editingRequestId: $editingRequestId, leaveTypeId: $leaveTypeId, dates: $dates, durationType: $durationType, returnToWorkOverride: $returnToWorkOverride, reason: $reason, submission: $submission)';
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
            const DeepCollectionEquality().equals(other._dates, _dates) &&
            (identical(other.durationType, durationType) ||
                other.durationType == durationType) &&
            (identical(other.returnToWorkOverride, returnToWorkOverride) ||
                other.returnToWorkOverride == returnToWorkOverride) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.submission, submission) ||
                other.submission == submission));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    editingRequestId,
    leaveTypeId,
    const DeepCollectionEquality().hash(_dates),
    durationType,
    returnToWorkOverride,
    reason,
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
    final List<DateTime> dates,
    final LeaveDurationType durationType,
    final DateTime? returnToWorkOverride,
    final String reason,
    final AsyncValue<LeaveRequest?> submission,
  }) = _$LeaveRequestFormStateImpl;
  const _LeaveRequestFormState._() : super._();

  @override
  /// Non-null once [LeaveRequestFormNotifier.seed] has run — i.e. edit mode.
  String? get editingRequestId;
  @override
  String? get leaveTypeId;
  @override
  List<DateTime> get dates;
  @override
  LeaveDurationType get durationType;
  @override
  DateTime? get returnToWorkOverride;
  @override
  String get reason;
  @override
  AsyncValue<LeaveRequest?> get submission;
  @override
  @JsonKey(ignore: true)
  _$$LeaveRequestFormStateImplCopyWith<_$LeaveRequestFormStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
