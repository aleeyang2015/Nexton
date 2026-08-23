// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'change_password_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ChangePasswordState {
  String get currentPassword => throw _privateConstructorUsedError;
  String get newPassword => throw _privateConstructorUsedError;
  String get confirmPassword => throw _privateConstructorUsedError;
  bool get obscureCurrent => throw _privateConstructorUsedError;
  bool get obscureNew => throw _privateConstructorUsedError;
  bool get obscureConfirm => throw _privateConstructorUsedError;
  String? get currentError => throw _privateConstructorUsedError;
  String? get newError => throw _privateConstructorUsedError;
  String? get confirmError => throw _privateConstructorUsedError;

  /// `true` once the password has actually been changed.
  AsyncValue<bool> get submission => throw _privateConstructorUsedError;

  /// Bumped when the current-password field must be re-typed, i.e. the
  /// server rejected the one that was entered. The page watches it and
  /// clears its controller.
  int get currentPasswordClearTick => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ChangePasswordStateCopyWith<ChangePasswordState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChangePasswordStateCopyWith<$Res> {
  factory $ChangePasswordStateCopyWith(
    ChangePasswordState value,
    $Res Function(ChangePasswordState) then,
  ) = _$ChangePasswordStateCopyWithImpl<$Res, ChangePasswordState>;
  @useResult
  $Res call({
    String currentPassword,
    String newPassword,
    String confirmPassword,
    bool obscureCurrent,
    bool obscureNew,
    bool obscureConfirm,
    String? currentError,
    String? newError,
    String? confirmError,
    AsyncValue<bool> submission,
    int currentPasswordClearTick,
  });
}

/// @nodoc
class _$ChangePasswordStateCopyWithImpl<$Res, $Val extends ChangePasswordState>
    implements $ChangePasswordStateCopyWith<$Res> {
  _$ChangePasswordStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentPassword = null,
    Object? newPassword = null,
    Object? confirmPassword = null,
    Object? obscureCurrent = null,
    Object? obscureNew = null,
    Object? obscureConfirm = null,
    Object? currentError = freezed,
    Object? newError = freezed,
    Object? confirmError = freezed,
    Object? submission = null,
    Object? currentPasswordClearTick = null,
  }) {
    return _then(
      _value.copyWith(
            currentPassword: null == currentPassword
                ? _value.currentPassword
                : currentPassword // ignore: cast_nullable_to_non_nullable
                      as String,
            newPassword: null == newPassword
                ? _value.newPassword
                : newPassword // ignore: cast_nullable_to_non_nullable
                      as String,
            confirmPassword: null == confirmPassword
                ? _value.confirmPassword
                : confirmPassword // ignore: cast_nullable_to_non_nullable
                      as String,
            obscureCurrent: null == obscureCurrent
                ? _value.obscureCurrent
                : obscureCurrent // ignore: cast_nullable_to_non_nullable
                      as bool,
            obscureNew: null == obscureNew
                ? _value.obscureNew
                : obscureNew // ignore: cast_nullable_to_non_nullable
                      as bool,
            obscureConfirm: null == obscureConfirm
                ? _value.obscureConfirm
                : obscureConfirm // ignore: cast_nullable_to_non_nullable
                      as bool,
            currentError: freezed == currentError
                ? _value.currentError
                : currentError // ignore: cast_nullable_to_non_nullable
                      as String?,
            newError: freezed == newError
                ? _value.newError
                : newError // ignore: cast_nullable_to_non_nullable
                      as String?,
            confirmError: freezed == confirmError
                ? _value.confirmError
                : confirmError // ignore: cast_nullable_to_non_nullable
                      as String?,
            submission: null == submission
                ? _value.submission
                : submission // ignore: cast_nullable_to_non_nullable
                      as AsyncValue<bool>,
            currentPasswordClearTick: null == currentPasswordClearTick
                ? _value.currentPasswordClearTick
                : currentPasswordClearTick // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChangePasswordStateImplCopyWith<$Res>
    implements $ChangePasswordStateCopyWith<$Res> {
  factory _$$ChangePasswordStateImplCopyWith(
    _$ChangePasswordStateImpl value,
    $Res Function(_$ChangePasswordStateImpl) then,
  ) = __$$ChangePasswordStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String currentPassword,
    String newPassword,
    String confirmPassword,
    bool obscureCurrent,
    bool obscureNew,
    bool obscureConfirm,
    String? currentError,
    String? newError,
    String? confirmError,
    AsyncValue<bool> submission,
    int currentPasswordClearTick,
  });
}

/// @nodoc
class __$$ChangePasswordStateImplCopyWithImpl<$Res>
    extends _$ChangePasswordStateCopyWithImpl<$Res, _$ChangePasswordStateImpl>
    implements _$$ChangePasswordStateImplCopyWith<$Res> {
  __$$ChangePasswordStateImplCopyWithImpl(
    _$ChangePasswordStateImpl _value,
    $Res Function(_$ChangePasswordStateImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentPassword = null,
    Object? newPassword = null,
    Object? confirmPassword = null,
    Object? obscureCurrent = null,
    Object? obscureNew = null,
    Object? obscureConfirm = null,
    Object? currentError = freezed,
    Object? newError = freezed,
    Object? confirmError = freezed,
    Object? submission = null,
    Object? currentPasswordClearTick = null,
  }) {
    return _then(
      _$ChangePasswordStateImpl(
        currentPassword: null == currentPassword
            ? _value.currentPassword
            : currentPassword // ignore: cast_nullable_to_non_nullable
                  as String,
        newPassword: null == newPassword
            ? _value.newPassword
            : newPassword // ignore: cast_nullable_to_non_nullable
                  as String,
        confirmPassword: null == confirmPassword
            ? _value.confirmPassword
            : confirmPassword // ignore: cast_nullable_to_non_nullable
                  as String,
        obscureCurrent: null == obscureCurrent
            ? _value.obscureCurrent
            : obscureCurrent // ignore: cast_nullable_to_non_nullable
                  as bool,
        obscureNew: null == obscureNew
            ? _value.obscureNew
            : obscureNew // ignore: cast_nullable_to_non_nullable
                  as bool,
        obscureConfirm: null == obscureConfirm
            ? _value.obscureConfirm
            : obscureConfirm // ignore: cast_nullable_to_non_nullable
                  as bool,
        currentError: freezed == currentError
            ? _value.currentError
            : currentError // ignore: cast_nullable_to_non_nullable
                  as String?,
        newError: freezed == newError
            ? _value.newError
            : newError // ignore: cast_nullable_to_non_nullable
                  as String?,
        confirmError: freezed == confirmError
            ? _value.confirmError
            : confirmError // ignore: cast_nullable_to_non_nullable
                  as String?,
        submission: null == submission
            ? _value.submission
            : submission // ignore: cast_nullable_to_non_nullable
                  as AsyncValue<bool>,
        currentPasswordClearTick: null == currentPasswordClearTick
            ? _value.currentPasswordClearTick
            : currentPasswordClearTick // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$ChangePasswordStateImpl extends _ChangePasswordState {
  const _$ChangePasswordStateImpl({
    this.currentPassword = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.obscureCurrent = true,
    this.obscureNew = true,
    this.obscureConfirm = true,
    this.currentError = null,
    this.newError = null,
    this.confirmError = null,
    this.submission = const AsyncValue.data(false),
    this.currentPasswordClearTick = 0,
  }) : super._();

  @override
  @JsonKey()
  final String currentPassword;
  @override
  @JsonKey()
  final String newPassword;
  @override
  @JsonKey()
  final String confirmPassword;
  @override
  @JsonKey()
  final bool obscureCurrent;
  @override
  @JsonKey()
  final bool obscureNew;
  @override
  @JsonKey()
  final bool obscureConfirm;
  @override
  @JsonKey()
  final String? currentError;
  @override
  @JsonKey()
  final String? newError;
  @override
  @JsonKey()
  final String? confirmError;

  /// `true` once the password has actually been changed.
  @override
  @JsonKey()
  final AsyncValue<bool> submission;

  /// Bumped when the current-password field must be re-typed, i.e. the
  /// server rejected the one that was entered. The page watches it and
  /// clears its controller.
  @override
  @JsonKey()
  final int currentPasswordClearTick;

  @override
  String toString() {
    return 'ChangePasswordState(currentPassword: $currentPassword, newPassword: $newPassword, confirmPassword: $confirmPassword, obscureCurrent: $obscureCurrent, obscureNew: $obscureNew, obscureConfirm: $obscureConfirm, currentError: $currentError, newError: $newError, confirmError: $confirmError, submission: $submission, currentPasswordClearTick: $currentPasswordClearTick)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChangePasswordStateImpl &&
            (identical(other.currentPassword, currentPassword) ||
                other.currentPassword == currentPassword) &&
            (identical(other.newPassword, newPassword) ||
                other.newPassword == newPassword) &&
            (identical(other.confirmPassword, confirmPassword) ||
                other.confirmPassword == confirmPassword) &&
            (identical(other.obscureCurrent, obscureCurrent) ||
                other.obscureCurrent == obscureCurrent) &&
            (identical(other.obscureNew, obscureNew) ||
                other.obscureNew == obscureNew) &&
            (identical(other.obscureConfirm, obscureConfirm) ||
                other.obscureConfirm == obscureConfirm) &&
            (identical(other.currentError, currentError) ||
                other.currentError == currentError) &&
            (identical(other.newError, newError) ||
                other.newError == newError) &&
            (identical(other.confirmError, confirmError) ||
                other.confirmError == confirmError) &&
            (identical(other.submission, submission) ||
                other.submission == submission) &&
            (identical(
                  other.currentPasswordClearTick,
                  currentPasswordClearTick,
                ) ||
                other.currentPasswordClearTick == currentPasswordClearTick));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    currentPassword,
    newPassword,
    confirmPassword,
    obscureCurrent,
    obscureNew,
    obscureConfirm,
    currentError,
    newError,
    confirmError,
    submission,
    currentPasswordClearTick,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChangePasswordStateImplCopyWith<_$ChangePasswordStateImpl> get copyWith =>
      __$$ChangePasswordStateImplCopyWithImpl<_$ChangePasswordStateImpl>(
        this,
        _$identity,
      );
}

abstract class _ChangePasswordState extends ChangePasswordState {
  const factory _ChangePasswordState({
    final String currentPassword,
    final String newPassword,
    final String confirmPassword,
    final bool obscureCurrent,
    final bool obscureNew,
    final bool obscureConfirm,
    final String? currentError,
    final String? newError,
    final String? confirmError,
    final AsyncValue<bool> submission,
    final int currentPasswordClearTick,
  }) = _$ChangePasswordStateImpl;
  const _ChangePasswordState._() : super._();

  @override
  String get currentPassword;
  @override
  String get newPassword;
  @override
  String get confirmPassword;
  @override
  bool get obscureCurrent;
  @override
  bool get obscureNew;
  @override
  bool get obscureConfirm;
  @override
  String? get currentError;
  @override
  String? get newError;
  @override
  String? get confirmError;
  @override
  /// `true` once the password has actually been changed.
  AsyncValue<bool> get submission;
  @override
  /// Bumped when the current-password field must be re-typed, i.e. the
  /// server rejected the one that was entered. The page watches it and
  /// clears its controller.
  int get currentPasswordClearTick;
  @override
  @JsonKey(ignore: true)
  _$$ChangePasswordStateImplCopyWith<_$ChangePasswordStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
