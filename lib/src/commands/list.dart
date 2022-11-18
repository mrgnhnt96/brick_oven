// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';

import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:usage/usage_io.dart';

/// {@template lists_command}
/// Lists the configured bricks within the config file
/// {@endtemplate}
class ListCommand extends BrickOvenCommand {
  /// {@macro lists_command}
  ListCommand({
    required Logger logger,
    required Analytics analytics,
    required FileSystem fileSystem,
  })  : _analytics = analytics,
        super(
          logger: logger,
          fileSystem: fileSystem,
        ) {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Lists the bricks with their file & dir configurations',
    );
  }

  final Analytics _analytics;

  @override
  String get description =>
      'Lists all configured bricks from ${BrickOvenYaml.file}';

  @override
  String get name => 'list';

  @override
  List<String> get aliases => ['ls'];

  @override
  Future<int> run() async {
    const tab = '  ';

    final bricksOrError = this.bricks();
    if (bricksOrError.isError) {
      logger.err(bricksOrError.error);
      return ExitCode.config.code;
    }

    final bricks = bricksOrError.bricks;

    for (final brick in bricks) {
      logger.info(
        '${cyan.wrap(brick.name)}: '
        '${darkGray.wrap(brick.source.sourceDir)}',
      );

      if (isVerbose) {
        final dirsString = 'dirs: ${yellow.wrap(brick.dirs.length.toString())}';
        final filesString =
            'files: ${yellow.wrap(brick.files.length.toString())}';
        final varsString =
            'vars: ${yellow.wrap(brick.allBrickVariables().length.toString())}';
        final partialsString =
            'partials: ${yellow.wrap(brick.partials.length.toString())}';

        logger.info(
          '$tab${darkGray.wrap('(configured)')} '
          '$dirsString, $filesString, $partialsString, $varsString',
        );
      }
    }

    unawaited(
      _analytics.sendEvent(
        'list',
        'bricks',
        value: ExitCode.success.code,
        parameters: {
          'bricks': bricks.toString(),
          'verbose': isVerbose.toString(),
        },
      ),
    );

    await _analytics.waitForLastPing(timeout: BrickOvenRunner.timeout);

    return ExitCode.success.code;
  }

  /// whether to list the output in verbose mode
  bool get isVerbose => argResults?['verbose'] as bool? ?? false;
}
