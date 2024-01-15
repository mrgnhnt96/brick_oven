// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';

import 'package:mason_logger/mason_logger.dart';

import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/domain/config/brick_oven_config.dart';
import 'package:brick_oven/domain/implementations/brick_impl.dart';
import 'package:brick_oven/domain/interfaces/brick.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/utils/brick_cooker.dart';
import 'package:brick_oven/utils/yaml_to_json.dart';

/// {@template lists_command}
/// Lists the configured bricks within the config file
/// {@endtemplate}
class ListCommand extends BrickOvenCommand with BrickCookerArgs {
  /// {@macro lists_command}
  ListCommand() {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Lists the bricks with their file & dir configurations',
    );
  }

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

    final configFile = BrickOvenYaml.findNearest(cwd);

    if (configFile == null) {
      throw Exception('Config file not found');
    }

    final json = YamlToJson.fromFile(configFile);

    final config = BrickOvenConfig.fromJson(json, configPath: configFile.path);

    final bricks = <Brick>{};

    for (final MapEntry(key: name, value: config)
        in config.resolveBricks().entries) {
      bricks.add(
        BrickImpl(
          config,
          name: name,
          outputDir: outputDir,
          watch: isWatch,
          shouldSync: shouldSync,
        ),
      );
    }

    for (final brick in bricks) {
      logger.info(
        '${cyan.wrap(brick.name)}: '
        '${darkGray.wrap(brick.source.path)}',
      );

      if (isVerbose) {
        final dirsString =
            'dirs: ${yellow.wrap(brick.directories.length.toString())}';
        final filesString =
            'files: ${yellow.wrap('${brick.fileConfigs?.keys.length ?? 0}')}';
        final varsString =
            'vars: ${yellow.wrap(brick.variables.length.toString())}';
        final partialsString =
            'partials: ${yellow.wrap(brick.partials.length.toString())}';

        logger.info(
          '$tab${darkGray.wrap('(configured)')} '
          '$dirsString, $filesString, $partialsString, $varsString',
        );
      }
    }

    return ExitCode.success.code;
  }

  /// whether to list the output in verbose mode
  bool get isVerbose => argResults?['verbose'] as bool? ?? false;
}
