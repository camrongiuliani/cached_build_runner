import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_build_runner/model/code_file.dart';
import 'package:cached_build_runner/utils/logger.dart';
import 'package:cached_build_runner/utils/utils.dart';
import 'package:pool/pool.dart';
import 'package:collection/src/iterable_extensions.dart';

class BuildRunnerWrapper {
  const BuildRunnerWrapper();

  List<List<T>> splitList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      final chunk = list.sublist(i, i + chunkSize.clamp(0, list.length - i));
      chunks.add(chunk);
    }
    return chunks;
  }

  Future<bool> runBuild(List<CodeFile> files,
      void Function(List<CodeFile> files) onChunkComplete) async {
    if (files.isEmpty) return true;
    Logger.header(
      'Generating Codes for non-cached files, found ${files.length} files',
    );

    Logger.v('Running build_runner build...', showPrefix: false);

    final pool = Pool(3);

    final fileLen = files
        .map((f) {
          return f.generatedOutput;
        })
        .flattened
        .length;

    Logger.i('Total Files: ${fileLen}');

    // final chunks = splitList(files, 5);
    final chunks = [files];

    Logger.i('Total Chunks: ${chunks.length}');

    int chunksComplete = 0;

    Completer completer = Completer();

    // Logger.d('Run: "flutter pub run build_runner build --build-filter $filterList"');
    var s = pool.forEach(
      chunks,
      (e) async {
        var paths = e
            .map(
              (e) => e.generatedOutput.map((e) {
                return e.path;
              }),
            )
            .flattened
            .where((p) => !p.endsWith('.freezed.dart'))
            .toList();

        Completer<void> completer = Completer();

        var filter = paths.join(',');

        var process = await Process.start(
          'dart',
          [
            // '--old_gen_heap_size=$heapSize',
            'run',
            'build_runner',
            'build',
            '--build-filter=$filter',
            '--delete-conflicting-outputs',
            '&',
          ],
          // workingDirectory: workingDirectory,
          mode: ProcessStartMode.detachedWithStdio,
          workingDirectory: Utils.projectDirectory,
          // runInShell: true,
        );

        process.stdout.listen(
          (event) {
            try {
              Logger.v(utf8.decode(event).trim(), showPrefix: false);
            } catch (e) {
              print('SDTDOUT');
            }
          },
          onDone: () async {
            if (!completer.isCompleted) {
              // Give process a little time to settle
              await Future<void>.delayed(const Duration(seconds: 1));
              chunksComplete++;

              var pctComplete = (chunksComplete / chunks.length) * 100;

              Logger.i('Chunks Complete: $chunksComplete / ${chunks.length}');
              Logger.i('Pct Complete: ${pctComplete.toStringAsFixed(2)}%');
              onChunkComplete(e);
              completer.complete();
            }
          },
        );

        process.stderr.listen((event) {
          if (!completer.isCompleted) {
            completer.complete();
          }
          final m = utf8.decode(event);

          if (m.isNotEmpty) {
            Logger.e('stderr --> $m');
          }
        });

        return completer.future.then((_) async {
          // Give process a little time to settle
          await Future<void>.delayed(const Duration(seconds: 3));
          process.kill();
          Logger.i('Killed Process');
        }).timeout(
          const Duration(
            minutes: 10,
          ),
          onTimeout: () {
            process.kill();
          },
        );
      },
    );

    s.listen(
      (p) {},
      onDone: () async {
        // Close the pool after all tasks are finished.
        await pool.close();
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    await completer.future;

    // final process = Process.runSync(
    //   'flutter',
    //   ['pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs', '--build-filter', filterList],
    //   workingDirectory: Utils.projectDirectory,
    //   runInShell: true,
    // );
    // final stdOut = process.stdout?.toString() ?? '';
    // final stdErrr = process.stderr?.toString() ?? '';
    // Logger.v(stdOut.trim(), showPrefix: false);
    //
    // if (stdErrr.trim().isNotEmpty) {
    //   Logger.e(stdErrr.trim());
    // }
    return true;
    // return p.exitCode == 0;
  }

}
