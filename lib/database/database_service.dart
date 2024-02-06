import 'dart:async';

import 'package:cached_build_runner/model/code_file.dart';

typedef Transaction<T> = Future<T> Function(DatabaseService db);

/// An interface for a database service used to cache generated code.
abstract class DatabaseService {
  /// Initializes the database service.
  Future<void> init();

  Future<List<GeneratedFile>> getAllData();

  /// Checks if the mapping is available for the given digest.
  FutureOr<bool> containsFile(GeneratedFile file);

  /// Gets the cached file path for the given digests in bulk.
  FutureOr<List<GeneratedFile>> getCachedFiles(
    Iterable<String> keys,
  );

  /// Gets the cached file path for the given digest.
  FutureOr<GeneratedFile?> getCachedFile(String key);

  /// Creates entries for the given cached file paths in bulk.
  Future<void> createEntries(List<GeneratedFile> files);

  /// Creates an entry for the given digest and cached file path.
  Future<void> createEntry(GeneratedFile file);

  /// Creates custom [entry] under [key].
  Future<void> createCustomEntry(String key, String entry);

  /// Gets entry by key.
  Future<String?> getEntryByKey(String key);

  /// Delete all records except [keysToKeep].
  Future<void> prune({required List<String> keysToKeep});

  /// Flushes the database service. Flushing to disk, or closing network connections
  /// could be done here.
  Future<void> flush();

  Future<T> transaction<T>(Transaction<T> transactionCallback);
}
