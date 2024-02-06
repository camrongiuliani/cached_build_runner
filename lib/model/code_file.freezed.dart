// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'code_file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

CodeFile _$CodeFileFromJson(Map<String, dynamic> json) {
  return _CodeFile.fromJson(json);
}

/// @nodoc
mixin _$CodeFile {
  String get path => throw _privateConstructorUsedError;
  String get digest => throw _privateConstructorUsedError;
  List<GeneratedFile> get generatedOutput => throw _privateConstructorUsedError;
  bool get isTestFile => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CodeFileCopyWith<CodeFile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CodeFileCopyWith<$Res> {
  factory $CodeFileCopyWith(CodeFile value, $Res Function(CodeFile) then) =
      _$CodeFileCopyWithImpl<$Res, CodeFile>;
  @useResult
  $Res call(
      {String path,
      String digest,
      List<GeneratedFile> generatedOutput,
      bool isTestFile});
}

/// @nodoc
class _$CodeFileCopyWithImpl<$Res, $Val extends CodeFile>
    implements $CodeFileCopyWith<$Res> {
  _$CodeFileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? digest = null,
    Object? generatedOutput = null,
    Object? isTestFile = null,
  }) {
    return _then(_value.copyWith(
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      digest: null == digest
          ? _value.digest
          : digest // ignore: cast_nullable_to_non_nullable
              as String,
      generatedOutput: null == generatedOutput
          ? _value.generatedOutput
          : generatedOutput // ignore: cast_nullable_to_non_nullable
              as List<GeneratedFile>,
      isTestFile: null == isTestFile
          ? _value.isTestFile
          : isTestFile // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_CodeFileCopyWith<$Res> implements $CodeFileCopyWith<$Res> {
  factory _$$_CodeFileCopyWith(
          _$_CodeFile value, $Res Function(_$_CodeFile) then) =
      __$$_CodeFileCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String path,
      String digest,
      List<GeneratedFile> generatedOutput,
      bool isTestFile});
}

/// @nodoc
class __$$_CodeFileCopyWithImpl<$Res>
    extends _$CodeFileCopyWithImpl<$Res, _$_CodeFile>
    implements _$$_CodeFileCopyWith<$Res> {
  __$$_CodeFileCopyWithImpl(
      _$_CodeFile _value, $Res Function(_$_CodeFile) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? digest = null,
    Object? generatedOutput = null,
    Object? isTestFile = null,
  }) {
    return _then(_$_CodeFile(
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      digest: null == digest
          ? _value.digest
          : digest // ignore: cast_nullable_to_non_nullable
              as String,
      generatedOutput: null == generatedOutput
          ? _value._generatedOutput
          : generatedOutput // ignore: cast_nullable_to_non_nullable
              as List<GeneratedFile>,
      isTestFile: null == isTestFile
          ? _value.isTestFile
          : isTestFile // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_CodeFile extends _CodeFile {
  const _$_CodeFile(
      {required this.path,
      required this.digest,
      required final List<GeneratedFile> generatedOutput,
      this.isTestFile = false})
      : _generatedOutput = generatedOutput,
        super._();

  factory _$_CodeFile.fromJson(Map<String, dynamic> json) =>
      _$$_CodeFileFromJson(json);

  @override
  final String path;
  @override
  final String digest;
  final List<GeneratedFile> _generatedOutput;
  @override
  List<GeneratedFile> get generatedOutput {
    if (_generatedOutput is EqualUnmodifiableListView) return _generatedOutput;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_generatedOutput);
  }

  @override
  @JsonKey()
  final bool isTestFile;

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_CodeFile &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.digest, digest) || other.digest == digest) &&
            const DeepCollectionEquality()
                .equals(other._generatedOutput, _generatedOutput) &&
            (identical(other.isTestFile, isTestFile) ||
                other.isTestFile == isTestFile));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, path, digest,
      const DeepCollectionEquality().hash(_generatedOutput), isTestFile);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_CodeFileCopyWith<_$_CodeFile> get copyWith =>
      __$$_CodeFileCopyWithImpl<_$_CodeFile>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_CodeFileToJson(
      this,
    );
  }
}

abstract class _CodeFile extends CodeFile {
  const factory _CodeFile(
      {required final String path,
      required final String digest,
      required final List<GeneratedFile> generatedOutput,
      final bool isTestFile}) = _$_CodeFile;
  const _CodeFile._() : super._();

  factory _CodeFile.fromJson(Map<String, dynamic> json) = _$_CodeFile.fromJson;

  @override
  String get path;
  @override
  String get digest;
  @override
  List<GeneratedFile> get generatedOutput;
  @override
  bool get isTestFile;
  @override
  @JsonKey(ignore: true)
  _$$_CodeFileCopyWith<_$_CodeFile> get copyWith =>
      throw _privateConstructorUsedError;
}
