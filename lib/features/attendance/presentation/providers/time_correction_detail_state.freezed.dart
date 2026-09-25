// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'time_correction_detail_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TimeCorrectionDetailState {
  AsyncValue<TimeCorrectionDetail> get detail =>
      throw _privateConstructorUsedError;
  bool get cancelling => throw _privateConstructorUsedError;
  bool get downloading => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TimeCorrectionDetailStateCopyWith<TimeCorrectionDetailState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimeCorrectionDetailStateCopyWith<$Res> {
  factory $TimeCorrectionDetailStateCopyWith(
    TimeCorrectionDetailState value,
    $Res Function(TimeCorrectionDetailState) then,
  ) = _$TimeCorrectionDetailStateCopyWithImpl<$Res, TimeCorrectionDetailState>;
  @useResult
  $Res call({
    AsyncValue<TimeCorrectionDetail> detail,
    bool cancelling,
    bool downloading,
  });
}

/// @nodoc
class _$TimeCorrectionDetailStateCopyWithImpl<
  $Res,
  $Val extends TimeCorrectionDetailState
>
    implements $TimeCorrectionDetailStateCopyWith<$Res> {
  _$TimeCorrectionDetailStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? detail = null,
    Object? cancelling = null,
    Object? downloading = null,
  }) {
    return _then(
      _value.copyWith(
            detail: null == detail
                ? _value.detail
                : detail // ignore: cast_nullable_to_non_nullable
                      as AsyncValue<TimeCorrectionDetail>,
            cancelling: null == cancelling
                ? _value.cancelling
                : cancelling // ignore: cast_nullable_to_non_nullable
                      as bool,
            downloading: null == downloading
                ? _value.downloading
                : downloading // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TimeCorrectionDetailStateImplCopyWith<$Res>
    implements $TimeCorrectionDetailStateCopyWith<$Res> {
  factory _$$TimeCorrectionDetailStateImplCopyWith(
    _$TimeCorrectionDetailStateImpl value,
    $Res Function(_$TimeCorrectionDetailStateImpl) then,
  ) = __$$TimeCorrectionDetailStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    AsyncValue<TimeCorrectionDetail> detail,
    bool cancelling,
    bool downloading,
  });
}

/// @nodoc
class __$$TimeCorrectionDetailStateImplCopyWithImpl<$Res>
    extends
        _$TimeCorrectionDetailStateCopyWithImpl<
          $Res,
          _$TimeCorrectionDetailStateImpl
        >
    implements _$$TimeCorrectionDetailStateImplCopyWith<$Res> {
  __$$TimeCorrectionDetailStateImplCopyWithImpl(
    _$TimeCorrectionDetailStateImpl _value,
    $Res Function(_$TimeCorrectionDetailStateImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? detail = null,
    Object? cancelling = null,
    Object? downloading = null,
  }) {
    return _then(
      _$TimeCorrectionDetailStateImpl(
        detail: null == detail
            ? _value.detail
            : detail // ignore: cast_nullable_to_non_nullable
                  as AsyncValue<TimeCorrectionDetail>,
        cancelling: null == cancelling
            ? _value.cancelling
            : cancelling // ignore: cast_nullable_to_non_nullable
                  as bool,
        downloading: null == downloading
            ? _value.downloading
            : downloading // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$TimeCorrectionDetailStateImpl implements _TimeCorrectionDetailState {
  const _$TimeCorrectionDetailStateImpl({
    this.detail = const AsyncValue<TimeCorrectionDetail>.loading(),
    this.cancelling = false,
    this.downloading = false,
  });

  @override
  @JsonKey()
  final AsyncValue<TimeCorrectionDetail> detail;
  @override
  @JsonKey()
  final bool cancelling;
  @override
  @JsonKey()
  final bool downloading;

  @override
  String toString() {
    return 'TimeCorrectionDetailState(detail: $detail, cancelling: $cancelling, downloading: $downloading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimeCorrectionDetailStateImpl &&
            (identical(other.detail, detail) || other.detail == detail) &&
            (identical(other.cancelling, cancelling) ||
                other.cancelling == cancelling) &&
            (identical(other.downloading, downloading) ||
                other.downloading == downloading));
  }

  @override
  int get hashCode => Object.hash(runtimeType, detail, cancelling, downloading);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TimeCorrectionDetailStateImplCopyWith<_$TimeCorrectionDetailStateImpl>
  get copyWith =>
      __$$TimeCorrectionDetailStateImplCopyWithImpl<
        _$TimeCorrectionDetailStateImpl
      >(this, _$identity);
}

abstract class _TimeCorrectionDetailState implements TimeCorrectionDetailState {
  const factory _TimeCorrectionDetailState({
    final AsyncValue<TimeCorrectionDetail> detail,
    final bool cancelling,
    final bool downloading,
  }) = _$TimeCorrectionDetailStateImpl;

  @override
  AsyncValue<TimeCorrectionDetail> get detail;
  @override
  bool get cancelling;
  @override
  bool get downloading;
  @override
  @JsonKey(ignore: true)
  _$$TimeCorrectionDetailStateImplCopyWith<_$TimeCorrectionDetailStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
