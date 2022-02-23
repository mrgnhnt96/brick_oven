// ignore_for_file: overridden_fields

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:watcher/watcher.dart';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/key_listener.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:brick_oven/utils/mixins.dart';

/// {@template cook_single_brick_command}
/// Writes a single brick from the configuration file
/// {@endtemplate}
class CookSingleBrick extends BrickOvenCommand
    with QuitAfterMixin, ConfigWatcherMixin {
  /// {@macro cook_single_brick_command}
  CookSingleBrick(
    this.brick, {
    FileSystem? fileSystem,
    Logger? logger,
    FileWatcher? configWatcher,
  })  : configWatcher = configWatcher ?? FileWatcher(BrickOvenYaml.file),
        super(fileSystem: fileSystem, logger: logger) {
    argParser
      ..addFlagsAndOptions()
      ..addSeparator('${'-' * 79}\n');
  }

  /// The brick to cook
  final Brick brick;

  /// whether to watch for file changes
  bool get isWatch => argResults['watch'] == true;

  /// The output directory
  String get outputDir => argResults['output'] as String? ?? 'bricks';

  @override
  final FileWatcher configWatcher;

  @override
  String get description => 'Cook the brick: $name.';

  @override
  String get name => brick.name;

  @override
  Future<int> run() async {
    logger.cooking();

    if (!isWatch) {
      brick.cook(output: outputDir);

      return ExitCode.success.code;
    }

    brick.source.watcher?.addEvent(logger.cooking, runBefore: true);
    brick.source.watcher?.addEvent(logger.watching, runAfter: true);
    brick.source.watcher?.addEvent(logger.qToQuit, runAfter: true);
    brick.source.watcher?.addEvent(() => fileChanged(logger: logger));

    brick.cook(output: outputDir, watch: true);

    logger.watching();

    if (!(brick.source.watcher?.isRunning ?? false)) {
      logger.err(
        'There are no bricks currently watching local files, ending',
      );

      return ExitCode.ioError.code;
    }

    if (stdin.hasTerminal) {
      qToQuit(logger: logger);
    }

    final ovenNeedsReset = await watchForConfigChanges(
      onChange: () async {
        logger.alert(
          '${BrickOvenYaml.file} changed, updating bricks configuration',
        );

        await brick.source.watcher?.stop();
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
