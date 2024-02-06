import 'dart:io';

import 'package:cached_build_runner/database/database_factory.dart';
import 'package:cached_build_runner/database/database_service.dart';
import 'package:cached_build_runner/model/code_file.dart';
import 'package:cached_build_runner/utils/constants.dart';
import 'package:cached_build_runner/utils/digest_utils.dart';
import 'package:cached_build_runner/utils/logger.dart';
import 'package:cached_build_runner/utils/utils.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as path;

typedef CachedFilesResult = ({List<CodeFile> cached, List<CodeFile> notCached});

class CacheProvider {
  final DatabaseFactory _databaseFactory;

  DatabaseService? __database;

  Future<DatabaseService> get _database async {
    final dbInstance = __database;
    if (dbInstance == null) {
      final db = await _databaseFactory.create();
      __database = db;

      return db;
    }

    return dbInstance;
  }

  CacheProvider({DatabaseFactory? databaseFactory})
      : _databaseFactory = databaseFactory ?? GetIt.I<DatabaseFactory>();

  Future<void> ensurePruning() async {
    if (!Utils.isPruneEnabled) return;

    final database = await _database;

    Logger.i('Pruning is enabled - checking pubpsec.lock');

    final pubspecLockPath =
        path.join(Utils.projectDirectory, Constants.pubpsecLockFileName);
    final pubspecLock = File(pubspecLockPath);

    final fileExists = pubspecLock.existsSync();

    if (!fileExists) {
      Logger.e('No ${Constants.pubpsecLockFileName} exits');

      return;
    }

    final digest = DigestUtils.generateDigestForSingleFile(pubspecLockPath);

    final existingDigest =
        await database.getEntryByKey(Constants.pubpsecLockFileName);

    Logger.v('Pubspec.lock digest: $digest');
    Logger.v('Existing Pubspec.lock digest: $digest');
    Logger.i('Needs prune: ${digest != existingDigest ? 'YES' : 'NO'}');

    if (existingDigest != null && digest != existingDigest) {
      Logger.i('Pruning cache as pubspec.lock has changed');
      await database.prune(keysToKeep: [Constants.pubpsecLockFileName]);
    }

    await _dbOperation((db) {
      return db.createCustomEntry(Constants.pubpsecLockFileName, digest);
    });
  }

  Future<CachedFilesResult> determineCache(List<CodeFile> files) async {
    final cached = <CodeFile>[];
    final notCached = <CodeFile>[];

    await _dbOperation(
      (db) async {
        for (final file in files) {
          var valid = true;

          for (final output in file.generatedOutput) {
            final cached = await db.getCachedFile(output.key);

            if (cached == null || cached.ownerDigest != file.digest) {
              notCached.add(file);
              valid = false;
              break;
            }
          }

          if (valid) {
            cached.add(file);
          }
        }
      },
    );

    return (cached: cached, notCached: notCached);
  }

  Future<void> cacheOutput(
    Iterable<GeneratedFile> outputs,
    void Function(GeneratedFile) onError,
  ) async {
    if (outputs.isEmpty) {
      return Logger.header('No new files to cache');
    }

    Logger.header('Caching ${outputs.length} files');

    final cacheEntries = <GeneratedFile>[];

    for (final output in outputs) {
      final generatedCodeFile = File(output.genOutputPath);

      if (!generatedCodeFile.existsSync()) {
        onError(output);
        Logger.i('Waiting on dep for ${output.genOutputPath}');
        continue;
      }

      generatedCodeFile.copySync(output.cachedFilePath);

      if (File(output.cachedFilePath).existsSync()) {
        cacheEntries.add(output);
      }
    }

    /// create a bulk entry
    await _dbOperation((db) => db.createEntries(cacheEntries));
  }

  Future<void> copyGeneratedCodesFor(List<CodeFile> cached) async {
    Logger.header('Checking cache for valid files.');

    for (final file in cached) {
      for (final output in file.generatedOutput) {
        final genSrc = File(output.genOutputPath);
        final cacheSrc = File(output.cachedFilePath);

        if (cacheSrc.existsSync()) {
          if (genSrc.existsSync()) {
            final srcDigest = DigestUtils.generateDigestForSingleFile(genSrc.path);
            final cacheDigest = DigestUtils.generateDigestForSingleFile(genSrc.path);

            if (srcDigest == cacheDigest) {
              Logger.v('Skipping copy for ${output.name}, file has not changed.');
              continue;
            }

            genSrc.deleteSync();
          }

          cacheSrc.copySync(genSrc.path);
          Logger.v('Copied ${output.name} from cache');
        }
      }
    }

    // for (final file in files) {
    //   final cachedGeneratedCodePath = await _dbOperation(
    //     (db) async => await db.getCachedFilePath(file.digest),
    //   );
    //   final generatedFilePath = file.getGeneratedFilePath();
    //
    //   Logger.v('Copying file: ${Utils.getFileName(generatedFilePath)}');
    //   final copiedFile = File(cachedGeneratedCodePath).copySync(generatedFilePath);
    //
    //   /// check if the file was copied successfully
    //   if (!copiedFile.existsSync()) {
    //     Logger.e(
    //       'ERROR: _copyGeneratedCodesFor: failed to copy the cached file $file',
    //     );
    //   }
    // }
  }

  Future<void> prune() {
    return _dbOperation((db) => db.prune(keysToKeep: []));
  }

  Future<List<GeneratedFile>> listCachedFiles() {
    return _dbOperation((db) => db.getAllData());
  }

  Future<T> _dbOperation<T>(Transaction<T> op) async {
    final db = await _database;

    return db.transaction(op);
  }
}
