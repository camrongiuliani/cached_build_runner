import 'package:cached_build_runner/utils/utils.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as pathUtils;

typedef GenFileDefinition = ({String sourcePath, String? suffix, CodeFileGeneratedType type});

enum CodeFileGeneratedType {
  import,
  partFile,
}

class CodeFile {
  final String path;
  final String digest;
  final bool isTestFile;
  final List<GeneratedFile> generatedOutput;

  const CodeFile({
    required this.path,
    required this.digest,
    required this.generatedOutput,
    this.isTestFile = false,
  });

  String get preferredGenFilter {
    return generatedOutput.firstWhereOrNull((o) {
      return o.suffix == 'g';
    })?.path ?? '';
  }

  @override
  String toString() {
    return '($path, $digest, $isTestFile, Outputs: ${generatedOutput.length})';
  }
}

class GeneratedFile {
  final String path;
  final String sourceDigest;
  final String sourcePath;
  final String? suffix;
  final CodeFileGeneratedType generatedType;

  const GeneratedFile({
    required this.path,
    required this.sourceDigest,
    required this.sourcePath,
    required this.suffix,
    required this.generatedType,
  });
}
