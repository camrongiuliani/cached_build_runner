import 'dart:async';
import 'dart:convert';

import 'package:cached_build_runner/database/database_service.dart';
import 'package:cached_build_runner/model/code_file.dart';
import 'package:hive/hive.dart';

/// An implementation of [DatabaseService] using Hive.
class HiveDatabaseService implements DatabaseService {
  final String dirPath;

  static const _tag = 'HiveDatabaseService';
  static const _boxName = 'generated-file-box';

  late Box<String> _box;

  HiveDatabaseService(this.dirPath);

  @override
  Future<void> init() async {
    Hive.init(dirPath);
    _box = await Hive.openBox<String>(_boxName);
  }

  @override
  FutureOr<bool> containsFile(GeneratedFile file) {
    return _box.containsKey(file.key);
  }

  @override
  FutureOr<GeneratedFile?> getCachedFile(String key) {
    final str = _box.get(key);
    if (str == null) {
      return null;
    }

    return GeneratedFile.fromJson(
      jsonDecode(str) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> createEntry(GeneratedFile file) {
    return _box.put(
      file.key,
      jsonEncode(
        file.toJson(),
      ),
    );
  }

  @override
  Future<void> createEntries(List<GeneratedFile> files) async {
    for (final file in files) {
      await createEntry(file);
    }
  }

  @override
  Future<void> flush() {
    return _box.flush();
  }

  @override
  FutureOr<List<GeneratedFile>> getCachedFiles(Iterable<String> keys) async {
    final files = <GeneratedFile>[];

    for (final key in keys) {
      final value = _box.get(key);

      if (value != null) {
        files.add(
          GeneratedFile.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        );
      }
    }

    return files;
  }

  @override
  Future<void> createCustomEntry(String key, String entry) {
    return _box.put(key, entry);
  }

  @override
  Future<String?> getEntryByKey(String key) async {
    return _box.get(key);
  }

  @override
  Future<void> prune({required List<String> keysToKeep}) async {
    final saved = <String, String>{};

    for (final key in keysToKeep) {
      final value = _box.get(key);
      if (value != null) saved[key] = value;
    }

    final _ = await _box.clear();

    for (final key in keysToKeep) {
      await _box.put(key, saved[key]!);
    }

    await flush();
  }

  @override
  Future<T> transaction<T>(Transaction<T> transactionCallback) async {
    final result = await transactionCallback(this);

    await flush();

    return result;
  }

  @override
  Future<List<GeneratedFile>> getAllData() async {
    return _box.values.where((v) {
      return v.startsWith('{') || v.startsWith('[');
    }).map((e) {
      return GeneratedFile.fromJson(
        jsonDecode(e) as Map<String, dynamic>,
      );
    }).toList();
  }
}
