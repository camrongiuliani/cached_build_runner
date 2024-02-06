import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:cached_build_runner/model/code_file.dart';
import 'package:cached_build_runner/utils/logger.dart';
import 'package:cached_build_runner/utils/utils.dart';
import 'package:collection/collection.dart';
import 'package:pool/pool.dart';

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

  Future<bool> runBuild(
    List<CodeFile> files,
    void Function(List<GeneratedFile> files) onChunkComplete,
  ) async {
    if (files.isEmpty) return true;
    Logger.header(
      'Generating Codes for non-cached files, found ${files.length} files',
    );

    Logger.v('Running build_runner build...', showPrefix: false);

    final buildTimes = <int>[];

    final pool = Pool(3);

    final fileLen = files
        .map((f) {
          return f.generatedOutput;
        })
        .flattened
        .length;

    Logger.i('Total Files: $fileLen');

    final chunks = splitList(files, 10);

    Logger.i('Total Chunks: ${chunks.length}');

    var chunksComplete = 0;

    final completer = Completer<void>();

    // Logger.d('Run: "flutter pub run build_runner build --build-filter $filterList"');
    final s = pool.forEach(
      chunks,
      (e) async {
        final stopWatch = Stopwatch()..start();

        final paths = e
            .map(
              (e) => e.generatedOutput.map((e) {
                return e.genOutputPath;
              }),
            )
            .flattened
            .where((p) => !p.endsWith('.freezed.dart'))
            .toList();

        final completer = Completer<void>();

        final filter = paths.join(',');

        final process = await Process.start(
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
              final msg = utf8.decode(event).trim();

              if (!msg.contains('[INFO]')) {
                Logger.v(utf8.decode(event).trim(), showPrefix: false);
              }
            } on Exception catch (e) {
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

              stopWatch.stop();
              buildTimes.add(stopWatch.elapsedMilliseconds);

              if (buildTimes.length >= 10) {
                printTimeRemaining(
                  buildTimes: buildTimes,
                  chunksLen: chunks.length,
                  chunksComplete: chunksComplete,
                );
              } else {
                Logger.i('Time remaining to be calculated after 10 chunks');
              }

              onChunkComplete(
                e.map((e) => e.generatedOutput).flattened.toList(),
              );
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

  void printTimeRemaining({
    required List<int> buildTimes,
    required int chunksLen,
    required int chunksComplete,
  }) {
    final avg = buildTimes.reduce((a, b) => a + b) / buildTimes.length;
    final avgSec = avg / 1000;
    Logger.i('Avg Seconds / Chunk: ${avgSec.toStringAsFixed(2)}');

    final minutesRemain = (avgSec / 60) * (chunksLen - chunksComplete);
    final str = formatMinutesToHoursMinutes(minutesRemain.toInt());
    Logger.i('Time Remaining: $str');
  }

  String formatMinutesToHoursMinutes(int minutes) {
    // Calculate hours and remaining minutes
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    // Format hours and minutes with leading zeros for single digits
    final hoursStr = hours.toString().padLeft(2, '0');
    final minutesStr = remainingMinutes.toString().padLeft(2, '0');

    // Combine formatted hours and minutes with a colon
    return '${hoursStr}h ${minutesStr}m';
  }
}
