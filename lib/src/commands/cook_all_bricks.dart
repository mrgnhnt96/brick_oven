import 'dart:async';

import 'package:args/args.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template cook_all_bricks_command}
/// Writes all bricks from the configuration file
/// {@endtemplate}
class CookAllBricks extends BrickOvenCommand {
  /// {@macro cook_all_bricks_command}
  CookAllBricks({
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
