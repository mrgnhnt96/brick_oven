import 'package:args/command_runner.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/domain/bricks_or_error.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';

/// {@template brick_oven_command}
/// The base command for all brick oven commands
/// {@endtemplate}
abstract class BrickOvenCommand extends Command<int> {
  /// {@macro brick_oven_command}
  BrickOvenCommand();

  /// the file system to be used for all file operations
  FileSystem get fileSystem => di<FileSystem>();

  /// the logger to be used for all logging
  Logger get logger => di<Logger>();

  /// gets the current working directory
  Directory get cwd {
    return fileSystem.currentDirectory;
  }

  /// gets the bricks brick oven configuration file
  BricksOrError bricks() {
    final configFile = BrickOvenYaml.findNearest(cwd);

    if (configFile == null) {
      return const BricksOrError(null, 'No ${BrickOvenYaml.file} file found');
    }

    YamlValue config;

    try {
      config = YamlValue.from(loadYaml(configFile.readAsStringSync()));
    } catch (e) {
      return BricksOrError(null, 'Invalid configuration, $e');
    }

    if (config.isError() || !config.isYaml()) {
      return const BricksOrError(null, 'Invalid brick oven configuration file');
    }

    final bricks = <Brick>{};

    final data = Map<String, dynamic>.from(config.asYaml().value);

    final bricksYaml = YamlValue.from(data.remove('bricks'));

    if (!bricksYaml.isYaml()) {
      return const BricksOrError(null, 'Bricks must be of type `Map`');
    }

    try {
      for (final brickData in bricksYaml.asYaml().value.entries) {
        final name = brickData.key as String;
        final value = YamlValue.from(brickData.value);

        YamlValue yaml;
        String? configPath;

        if (value.isYaml()) {
          yaml = value.asYaml();
        } else if (value.isString()) {
          final path = value.asString().value;
          final file = fileSystem.file(path);

          if (!file.existsSync()) {
            logger
                .warn('Brick configuration file not found | ($name) -- $path');
            continue;
          }

          final yamlValue = YamlValue.from(loadYaml(file.readAsStringSync()));

          if (!yamlValue.isYaml()) {
            return BricksOrError(
              null,
              'Brick configuration file must be of '
              'type `Map` | ($name) -- $path',
            );
          }

          yaml = yamlValue.asYaml();
          configPath = path;
        } else {
          final err = BrickException(
            brick: name,
            reason: 'Expected `Map` or '
                '`String` (path to brick configuration file)',
          );
          return BricksOrError(null, err.message);
        }

        final brick = Brick.fromYaml(
          yaml,
          name,
          configPath: configPath,
        );

        bricks.add(brick);
      }
    } on ConfigException catch (e) {
      return BricksOrError(null, e.message);
    } catch (e) {
      return const BricksOrError(null, 'Invalid brick configuration');
    }

    if (data.keys.isNotEmpty) {
      final error = BrickOvenException(
        'Invalid ${BrickOvenYaml.file} config:\n'
        'Unknown keys: "${data.keys.join('", "')}"',
      );
      return BricksOrError(null, error.message);
    }
    return BricksOrError(bricks, null);
  }
}
