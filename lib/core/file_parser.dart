import 'dart:io';

import 'package:cached_build_runner/core/dependency_visitor.dart';
import 'package:cached_build_runner/model/code_file.dart';
import 'package:cached_build_runner/utils/constants.dart';
import 'package:cached_build_runner/utils/digest_utils.dart';
import 'package:cached_build_runner/utils/extension.dart';
import 'package:cached_build_runner/utils/logger.dart';
import 'package:cached_build_runner/utils/utils.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as path;

class FileParser {
  final DependencyVisitor _dependencyVisitor;

  FileParser({DependencyVisitor? dependencyVisitor})
      : _dependencyVisitor = dependencyVisitor ?? GetIt.I<DependencyVisitor>();

  /// Returns a list of [CodeFile] instances that represent the files that need code generation.
  List<CodeFile> getFilesNeedingGeneration() {
    /// Files in "lib/" that needs code generation
    final libDirectory = Directory(path.join(Utils.projectDirectory, 'lib'));

    final libFiles = libDirectory
        .listSync(
          recursive: true,
          followLinks: false,
        )
        .where((f) => !f.path.contains('.build_cache'));

    final codeFiles = <CodeFile>[];

    for (final entity in libFiles) {
      if (entity is! File || !entity.isDartSourceCodeFile()) continue;

      final outputs = _parseFile(entity);

      if (outputs.isNotEmpty) {
        codeFiles.add(
          CodeFile(
            path: entity.path,
            digest: DigestUtils.generateDigestForClassFile(
              _dependencyVisitor,
              entity.path,
            ),
            generatedOutput: outputs.map((e) {
              return GeneratedFile(
                sourcePath: entity.path,
                path: entity.path.replaceAll('.dart', '.${e.suffix ?? 'g'}.dart'),
                suffix: e.suffix,
                sourceDigest: DigestUtils.generateDigestForClassFile(
                  _dependencyVisitor,
                  entity.path,
                ),
                generatedType: e.type,
              );
            }).toList(),
          ),
        );
      }
    }

    Logger.i(
      'Found ${codeFiles.length} files in "lib/" that supports code generation',
    );

    return codeFiles;
  }

  List<GenFileDefinition> _parseFile(File entity) {
    final outputs = <GenFileDefinition>[];

    final filePath = entity.path.trim();
    final fileContent = entity.readAsStringSync();

    final partMatches =
        Constants.partGeneratedFileRegex.allMatches(fileContent);

    if (partMatches.isNotEmpty) {
      for (final match in partMatches) {
        outputs.add(
          (
            sourcePath: filePath,
            suffix: match.group(1),
            type: CodeFileGeneratedType.partFile
          ),
        );
      }
      return outputs;
    }

    final importMatches =
        Constants.partGeneratedFileRegex.allMatches(fileContent);

    if (importMatches.isNotEmpty) {
      for (final match in importMatches) {
        outputs.add(
          (
            sourcePath: filePath,
            suffix: match.group(1),
            type: CodeFileGeneratedType.import,
          ),
        );
      }
      return outputs;
    }

    return outputs;
  }
}
