/// This library contains the [CachedBuildRunner] class that provides an efficient way to run `build_runner build`
/// by determining the files that need code generation and generating only the required code files. It uses caching
/// to avoid unnecessary generation builds and only generates codes for files that don't have cached versions.
///
/// Imports:
///
///   - `dart:io` for file I/O operations.
///   - `package:path/path.dart` for path manipulation.
///   - `database/database_service.dart` for interacting with the database service. Redis for running multiple instances
///      (such as in a pipeline) and hive if a single instance is using (such as in dev environment)
///   - `model/code_file.dart` for the [CodeFile] class that represents a code file.
///   - `utils/log.dart` for logging messages to the console.
///   - `utils/utils.dart` for utility functions.

library cached_build_runner;

import 'dart:async';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:barbecue/barbecue.dart';
import 'package:cached_build_runner/core/build_runner_wrapper.dart';
import 'package:cached_build_runner/core/cache_provider.dart';
import 'package:cached_build_runner/core/file_parser.dart';
import 'package:cached_build_runner/model/code_file.dart';
import 'package:cached_build_runner/utils/digest_utils.dart';
import 'package:cached_build_runner/utils/extension.dart';
import 'package:cached_build_runner/utils/logger.dart';
import 'package:cached_build_runner/utils/utils.dart';
import 'package:collection/collection.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as path;
import 'package:synchronized/synchronized.dart' as sync;

typedef _CachedFileInfo = ({String path, String digest, bool dirty});

class CachedBuildRunner implements Disposable {
  final FileParser _fileParser;
  final CacheProvider _cacheProvider;
  final BuildRunnerWrapper _buildRunnerWrapper;

  final Map<String, String> _contentDigestMap = {};
  final _buildLock = sync.Lock();

  StreamSubscription<FileSystemEvent>? _pubpsecWatch;
  StreamSubscription<FileSystemEvent>? _libWatch;

  CachedBuildRunner({
    FileParser? fileParser,
    CacheProvider? cacheProvider,
    BuildRunnerWrapper? buildRunnerWrapper,
  })  : _fileParser = fileParser ?? GetIt.I<FileParser>(),
        _cacheProvider = cacheProvider ?? GetIt.I<CacheProvider>(),
        _buildRunnerWrapper =
            buildRunnerWrapper ?? GetIt.I<BuildRunnerWrapper>();

  Future<void> watch() async {
    _watchForDependencyChanges();

    final libDirectory = Directory(path.join(Utils.projectDirectory, 'lib'));

    Logger.header(
      'Preparing to watch files in directory: ${Utils.projectDirectory}',
    );

    _generateContentHash(libDirectory);

    /// perform a first build operation
    await build();

    Logger.header('Watching for file changes.');

    // let's listen for file changes in the project directory
    // specifically in "lib" irectory
    _libWatch =
        libDirectory.watchDartSourceCodeFiles().listen(_onFileSystemEvent);
  }

  /// Runs an efficient version of `build_runner build` by determining which
  /// files need code generation and then either retrieving cached files,
  /// generating new files, or caching new generated files.
  ///
  /// To determine which files need code generation, this method first fetches
  /// all the Dart files in the `lib` directory and any test files in the
  /// `test` directory that contain the `@Generate` annotation.
  ///
  /// It then checks the database to see if generated files are available for
  /// these files. If so, it copies the cached files to their appropriate
  /// location in the project directory. If not, it generates the necessary
  /// files and caches them for future use.
  ///
  /// Finally, if Hive is used, it flushes Hive to ensure that everything is committed to disk.
  /// Otherwise, closes any connection open to Redis.
  ///
  ///   Throws:
  ///
  ///   - [Exception] if there is an error while running `build_runner build` command.

  Future<void> build() async {
    Logger.header('Determining Files that needs code generation');

    await _cacheProvider.ensurePruning();

    final libFiles = _fileParser.getFilesNeedingGeneration();
    final files = List<CodeFile>.of(libFiles);

    final (:cached, :notCached) = await _cacheProvider.determineCache(files);

    final numCached = cached
        .map((e) {
          return e.generatedOutput;
        })
        .flattened
        .length;

    final numNotCached = notCached
        .map((e) {
          return e.generatedOutput;
        })
        .flattened
        .length;

    Logger.i('No. of cached files: $numCached');
    Logger.i('No. of non-cached files: $numNotCached');

    if (numNotCached == 0) {
      return Logger.header('Nice! There is nothing to generate.');
    }

    await _cacheProvider.copyGeneratedCodesFor(cached);

    final errorFiles = <GeneratedFile>[];

    /// let's handle bad files - by generating the .g.dart / .mocks.dart files for them
    final success = await _buildRunnerWrapper.runBuild(
      notCached,
      (files) async {
        /// at last, let's cache the bad files - they may be required next time
        await _cacheProvider.cacheOutput(
          files,
          errorFiles.add,
        );
      },
    );

    if (errorFiles.isNotEmpty) {
      Logger.i('Re-Attempting ${errorFiles.length} failed outputs');
      final (:cached, :notCached) = await _cacheProvider.determineCache(files);

      await _cacheProvider.copyGeneratedCodesFor(cached);

      final success = await _buildRunnerWrapper.runBuild(
        notCached,
        (files) async {
          /// at last, let's cache the bad files - they may be required next time
          await _cacheProvider.cacheOutput(
            files,
            (errFile) {
              Logger.e('Error on second try of file: ${errFile.ownerPath}');
            },
          );
        },
      );
    }

    // if (!success) return;

    /// let's handle the good files - by copying the cached generated files to appropriate path
    // await _cacheProvider.copyGeneratedCodesFor(goodFiles);

    /// We are done, probably?
  }

  Future<void> hydrateCache() async {
    final libFiles = _fileParser.getFilesNeedingGeneration();

    final genFiles = libFiles
        .map((e) {
          return e.generatedOutput;
        })
        .flattened
        .where((output) {
          return File(output.genOutputPath).existsSync();
        });

    Logger.header('Hydrating cache with ${genFiles.length} files.');

    await _cacheProvider.cacheOutput(
      genFiles,
      (errFile) {
        Logger.e('Error hydrating ${errFile.name}');
      },
    );
  }

  Future<void> listAllCachedFiles() async {
    final libFiles = _fileParser.getFilesNeedingGeneration();
    final files = List<CodeFile>.of(libFiles);

    final mappedResult = await _cacheProvider.determineCache(files);

    final goodFiles = mappedResult.cached.map<_CachedFileInfo>(
        (e) => (path: e.path, digest: e.digest, dirty: false));
    final badFiles = mappedResult.notCached
        .map((e) => (path: e.path, digest: e.digest, dirty: true));

    final mappedFiles = [...goodFiles, ...badFiles].where((e) {
      return !e.dirty;
    }).toList()
      // .sublist(0, 50)
      ..sort((a, b) {
        return a.path.compareTo(b.path);
      });

    // final table = const TableRenderer(border: Border.simple).render(
    //   mappedFiles.map((e) => [e.path, e.digest, e.dirty].toList()),
    //   columns: [ColSpec(name: 'File'), ColSpec(name: 'Digest'), ColSpec(name: 'Dirty')],
    //   width: 100,
    // );
    final redPen = AnsiPen()..red(bold: true);
    final table = Table(
      cellStyle: const CellStyle(
        borderBottom: true,
        borderRight: true,
        borderLeft: true,
        borderTop: true,
        alignment: TextAlignment.MiddleLeft,
      ),
      header: const TableSection(
        rows: [
          Row(
            cells: [Cell('Path'), Cell('Digest'), Cell('Dirty')],
            cellStyle: CellStyle(borderBottom: true),
          ),
        ],
      ),
      body: TableSection(
        rows: mappedFiles
            .map<Row>(
              (e) => e.dirty
                  ? Row(
                      cells: [
                        Cell(redPen(e.path)),
                        Cell(redPen(e.digest)),
                        Cell(redPen(e.dirty.toString()))
                      ],
                    )
                  : Row(
                      cells: [
                        Cell(e.path),
                        Cell(e.digest),
                        Cell(e.dirty.toString())
                      ],
                    ),
            )
            .toList(),
      ),
    ).render(border: TextBorder.DEFAULT);

    //ignore: avoid_print, printing table.
    print(table);
  }

  @override
  Future<void> onDispose() async {
    await _pubpsecWatch?.cancel();
    await _libWatch?.cancel();
  }

  Future<void> prune() {
    Logger.header('Pruning cache directory');

    return _cacheProvider.prune();
  }

  bool _isCodeGenerationNeeded(FileSystemEvent e) {
    switch (e.type) {
      case FileSystemEvent.modify:
        final newDigest = DigestUtils.generateDigestForSingleFile(e.path);
        if (newDigest != _contentDigestMap[e.path]) {
          _contentDigestMap[e.path] = newDigest;

          return true;
        }

        return false;

      case FileSystemEvent.move:
      case FileSystemEvent.create:
        final digest = DigestUtils.generateDigestForSingleFile(e.path);
        _contentDigestMap[e.path] = digest;

        return true;

      case FileSystemEvent.delete:
        if (_contentDigestMap.containsKey(e.path)) {
          final _ = _contentDigestMap.remove(e.path);

          return true;
        }

        return false;
    }

    return false;
  }

  void _synchronizedBuild() {
    unawaited(_buildLock.synchronized(build));
  }

  void _onFileSystemEvent(FileSystemEvent event) {
    if (_isCodeGenerationNeeded(event)) {
      _synchronizedBuild();
    }
  }

  void _generateContentHash(Directory directory) {
    if (!directory.existsSync()) return;
    for (final entity in directory.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File && entity.isDartSourceCodeFile()) {
        _contentDigestMap[entity.path] =
            DigestUtils.generateDigestForSingleFile(
          entity.path,
        );
      }
    }
  }

  void _watchForDependencyChanges() {
    final pubspecFile = File(path.join(Utils.projectDirectory, 'pubspec.yaml'));
    final pubspecFileDigest = DigestUtils.generateDigestForSingleFile(
      pubspecFile.path,
    );

    _pubpsecWatch = pubspecFile.watch().listen((event) {
      final newPubspecFileDigest = DigestUtils.generateDigestForSingleFile(
        event.path,
      );

      if (newPubspecFileDigest != pubspecFileDigest) {
        Logger.i(
          'As pubspec.yaml file has been modified, terminating cached_build_runner.\nNo further builds will be scheduled. Please restart the build.',
        );
        exit(0);
      }
    });
  }
}

extension FileSystemEventExtensions on FileSystemEvent {
  String get name => switch (type) {
        FileSystemEvent.create => 'create',
        FileSystemEvent.move => 'move',
        FileSystemEvent.delete => 'delete',
        FileSystemEvent.modify => 'modify',
        _ => 'unknown $type',
      };
}
