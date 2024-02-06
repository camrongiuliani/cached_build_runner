import 'dart:io';

import 'package:cached_build_runner/model/generated_file.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

export 'generated_file.dart';

part 'code_file.freezed.dart';
part 'code_file.g.dart';

typedef GenFileDefinition = ({String sourcePath, String? suffix, CodeFileGeneratedType type});

enum CodeFileGeneratedType {
  import,
  partFile,
}

@freezed
class CodeFile with _$CodeFile {
  const CodeFile._();

  const factory CodeFile({
    required String path,
    required String digest,
    required List<GeneratedFile> generatedOutput,
    @Default(false) bool isTestFile,
  }) = _CodeFile;

  factory CodeFile.fromJson(Map<String, dynamic> json) =>
      _$CodeFileFromJson(json);

  int get outputLen {
    return generatedOutput.length;
  }

  String get preferredGenFilter {
    return generatedOutput.firstWhereOrNull((o) {
      return o.suffix == 'g';
    })?.suffix ?? 'freezed';
  }

  String get fileName {
    return path.split(Platform.pathSeparator).last;
  }

  @override
  String toString() {
    return '($path, $digest, $isTestFile, Outputs: ${generatedOutput.length})';
  }
}
