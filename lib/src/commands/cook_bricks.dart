import 'dart:async';

import 'package:args/args.dart';
import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template cook_bricks_command}
/// Writes the bricks from the configuration file
/// to the brick oven.
class CookBricksCommand extends BrickOvenCommand {
  /// {@macro cook_bricks_command}
  CookBricksCommand({
    FileSystem? fileSystem,
    Logger? logger,
  }) : super(fileSystem: fileSystem, logger: logger) {
    argParser.addFlagsAndOptions();

    addSubcommand(
      _CookAllBricks(
        fileSystem: fileSystem,
        logger: logger,
      ),
    );

    for (final brick in bricks) {
      addSubcommand(
        _CookSingleBrick(
          brick,
          fileSystem: fileSystem,
          logger: logger,
        ),
      );
    }
  }

  @override
  String get description => 'Cook 👨‍🍳 bricks from the config file.';

  @override
  String get name => 'cook';
}

class _CookAllBricks extends BrickOvenCommand {
  _CookAllBricks({
    FileSystem? fileSystem,
    Logger? logger,
  }) : super(fileSystem: fileSystem, logger: logger) {
    argParser
      ..addFlagsAndOptions()
      ..addSeparator('${'-' * 79}\n');
  }

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
      brick.cook(output: outputDir, watch: true);
    }

    logger.watching();

    if (!bricks.any((brick) => brick.source.watcher?.isRunning ?? false)) {
      logger.err(
        'There are no bricks currently watching local files, ending',
      );

      return ExitCode.ioError.code;
    }

    final ovenNeedsReset = await BrickOvenYaml.watchForChanges(
      onChange: () {
        logger.alert(
          '${BrickOvenYaml.file} changed, updating bricks configuration',
        );

        for (final brick in bricks) {
          brick.stopWatching();
        }
      },
    );

    if (ovenNeedsReset) {
      return ExitCode.tempFail.code;
    }

    return ExitCode.success.code;
  }
}

class _CookSingleBrick extends BrickOvenCommand {
  _CookSingleBrick(
    this.brick, {
    FileSystem? fileSystem,
    Logger? logger,
  }) : super(fileSystem: fileSystem, logger: logger) {
    argParser
      ..addFlagsAndOptions()
      ..addSeparator('${'-' * 79}\n');
  }

  final Brick brick;

  /// whether to watch for file changes
  bool get isWatch => argResults['watch'] == true;

  /// The output directory
  String get outputDir => argResults['output'] as String? ?? 'bricks';

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

    brick.cook(output: outputDir, watch: true);

    logger.watching();

    if (!(brick.source.watcher?.isRunning ?? false)) {
      logger.err(
        'There are no bricks currently watching local files, ending',
      );

      return ExitCode.ioError.code;
    }

    final ovenNeedsReset = await BrickOvenYaml.watchForChanges(
      onChange: () {
        logger.alert(
          '${BrickOvenYaml.file} changed, updating bricks configuration',
        );

        for (final brick in bricks) {
          brick.stopWatching();
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
    addOption(
      'output',
      abbr: 'o',
      help: 'Sets the output directory',
      valueHelp: 'path',
      defaultsTo: 'bricks',
    );

    addFlag(
      'watch',
      abbr: 'w',
      negatable: false,
      help: 'Watch the configuration file for changes and '
          're-cook the bricks as they change.',
    );
  }
}
