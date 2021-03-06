// ignore_for_file: overridden_fields

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:watcher/watcher.dart';

import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/key_listener.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:brick_oven/utils/mixins.dart';

/// {@template cook_all_bricks_command}
/// Writes all bricks from the configuration file
/// {@endtemplate}
class CookAllBricks extends BrickOvenCommand
    with QuitAfterMixin, ConfigWatcherMixin {
  /// {@macro cook_all_bricks_command}
  CookAllBricks({
    FileSystem? fileSystem,
    Logger? logger,
    FileWatcher? configWatcher,
    KeyPressListener? keyPressListener,
  })  : keyPressListener = keyPressListener ??
            KeyPressListener(
              stdin: stdin,
              logger: logger,
              toExit: exit,
            ),
        configWatcher = configWatcher ?? FileWatcher(BrickOvenYaml.file),
        super(fileSystem: fileSystem, logger: logger) {
    argParser
      ..addFlagsAndOptions()
      ..addSeparator('${'-' * 79}\n');
  }

  /// {@macro key_press_listener}
  final KeyPressListener keyPressListener;

  @override
  final FileWatcher configWatcher;

  @override
  String get description => 'Cook all bricks.';

  @override
  String get name => 'all';

  /// whether to watch for file changes
  bool get isWatch => argResults['watch'] == true;

  /// The output directory
  String get outputDir => argResults['output'] as String? ?? 'bricks';

  @override
  Future<int> run() async {
    logger.cooking();

    final bricks = this.bricks;

    if (!isWatch) {
      for (final brick in bricks) {
        brick.cook(output: outputDir);
      }
      logger.info('');

      return ExitCode.success.code;
    }

    for (final brick in bricks) {
      final watcher = brick.source.watcher;

      if (bricks.first == brick) {
        watcher?.addEvent(logger.cooking, runBefore: true);
      }

      if (bricks.last == brick) {
        watcher?.addEvent(logger.watching, runAfter: true);
        watcher?.addEvent(logger.qToQuit, runAfter: true);
      }

      watcher?.addEvent(() => fileChanged(logger: logger));
      brick.cook(output: outputDir, watch: true);
    }

    if (!bricks.any((brick) => brick.source.watcher?.isRunning ?? false)) {
      logger.err(
        'There are no bricks currently watching local files, ending',
      );

      return ExitCode.ioError.code;
    }

    logger.watching();

    keyPressListener.qToQuit();

    final ovenNeedsReset = await watchForConfigChanges(
      onChange: () async {
        logger.alert(
          '${BrickOvenYaml.file} changed, updating bricks configuration',
        );

        for (final brick in bricks) {
          await brick.source.watcher?.stop();
        }
      },
    );

    if (ovenNeedsReset) {
      return ExitCode.tempFail.code;
    }

    return ExitCode.success.code;
  }
}

extension on ArgParser {
  void addFlagsAndOptions() {
    output();

    watch();

    quitAfter();
  }
}
