import 'dart:io';

import 'package:cached_build_runner/model/code_file.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated_file.freezed.dart';
part 'generated_file.g.dart';

@freezed
class GeneratedFile with _$GeneratedFile {
  const GeneratedFile._();

  const factory GeneratedFile({
    required String ownerPath,
    required String genOutputPath,
    required String cachedFilePath,
    required String ownerDigest,
    required String? suffix,
    required CodeFileGeneratedType generatedType,
  }) = _GeneratedFile;

  String get key {
    return '${name}_$ownerDigest';
  }

  String get name {
    return genOutputPath.split(Platform.pathSeparator).last;
  }

  factory GeneratedFile.fromJson(Map<String, dynamic> json) =>
      _$GeneratedFileFromJson(json);
}
