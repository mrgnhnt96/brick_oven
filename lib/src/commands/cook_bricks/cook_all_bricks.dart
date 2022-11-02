// ignore_for_file: overridden_fields

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:brick_oven/src/exception.dart';
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
    KeyPressListener? keyPressListener,
  })  : configWatcher = FileWatcher(BrickOvenYaml.file),
        super(fileSystem: fileSystem, logger: logger) {
    argParser
      ..addFlagsAndOptions()
      ..addSeparator('${'-' * 79}\n');

    this.keyPressListener = keyPressListener ??
        keyPressListener ??
        KeyPressListener(
          stdin: stdin,
          logger: logger,
          toExit: (code) async {
            if (ExitCode.tempFail.code == code) {
              await cancelWatchers();
              return;
            }

            exit(code);
          },
        );
  }

  /// {@macro key_press_listener}
  late final KeyPressListener keyPressListener;

  /// the config watcher for the brick oven yaml
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

    final bricksOrError = this.bricks();
    if (bricksOrError.isError) {
      logger.err(bricksOrError.error);
      return ExitCode.config.code;
    }

    final bricks = bricksOrError.bricks;

    for (final brick in bricks) {
      if (isWatch) {
        final watcher = brick.source.watcher;

        watcher?.addEvent(
          () => logger.fileChanged(brick.name),
          runBefore: true,
        );
        watcher?.addEvent(logger.cooking, runBefore: true);
        watcher?.addEvent(logger.cooked, runAfter: true);
        watcher?.addEvent(logger.watching, runAfter: true);
        watcher?.addEvent(logger.keyStrokes, runAfter: true);
        watcher?.addEvent(() => fileChanged(logger: logger));
      }

      try {
        brick.cook(output: outputDir, watch: isWatch);
      } on ConfigException catch (e) {
        logger.err(e.message);
        return ExitCode.config.code;
      } catch (e) {
        logger.err('$e');
        return ExitCode.software.code;
      }
    }

    logger.cooked();

    if (!isWatch) {
      return ExitCode.success.code;
    }

    if (!bricks.any((brick) => brick.source.watcher?.isRunning ?? false)) {
      logger.err(
        'There are no bricks currently watching local files, ending',
      );

      return ExitCode.ioError.code;
    }

    logger.watching();

    keyPressListener.listenToKeystrokes();

    for (final brick in bricks) {
      if (brick.configPath == null) {
        continue;
      }

      unawaited(
        watchForConfigChanges(
          brick.configPath!,
          onChange: () async {
            logger.configChanged();

            await cancelWatchers();
            await brick.source.watcher?.stop();
          },
        ),
      );
    }

    final ovenNeedsReset = await watchForConfigChanges(
      BrickOvenYaml.file,
      onChange: () async {
        logger.configChanged();

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
