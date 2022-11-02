import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:brick_oven/domain/brick_or_error.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/extensions.dart';

/// {@template brick_oven_command}
/// The base command for all brick oven commands
/// {@endtemplate}
abstract class BrickOvenCommand extends Command<int> {
  /// {@macro brick_oven_command}
  BrickOvenCommand({
    FileSystem? fileSystem,
    Logger? logger,
  })  : fileSystem = fileSystem ?? const LocalFileSystem(),
        logger = logger ?? Logger();

  /// the file system to be used for all file operations
  final FileSystem fileSystem;

  /// the logger to be used for all logging
  final Logger logger;

  @override
  ArgResults get argResults => super.argResults!;

  /// gets the bricks brick oven configuration file
  BrickOrError get bricks {
    final configFile = BrickOvenYaml.findNearest(cwd);

    if (configFile == null) {
      throw const BrickOvenNotFoundException();
    }

    final config = loadYaml(configFile.readAsStringSync()) as YamlMap;

    final directories = <Brick>{};

    final data = config.data;

    final bricks = data.remove('bricks') as YamlMap?;

    if (bricks != null) {
      try {
        for (final brick in bricks.entries) {
          final name = brick.key as String;
          final value = YamlValue.from(brick.value);

          YamlMap? yaml;

          if (value.isYaml()) {
            yaml = value.asYaml().value;
          } else if (value.isString()) {
            final path = value.asString().value;
            final file = fileSystem.file(path);
            yaml = loadYaml(file.readAsStringSync()) as YamlMap;
          } else {
            throw BrickException(
              brick: name,
              reason: 'Invalid brick configuration -- Expected `Map` or '
                  '`String` (path to brick configuration file)',
            );
          }

          directories.add(Brick.fromYaml(name, yaml));
        }
      } on ConfigException catch (e) {
        return BrickOrError(null, e.message);
      } catch (e) {
        return BrickOrError(null, '$e');
      }
    }

    if (data.keys.isNotEmpty) {
      final error = UnknownKeysException(
        data.keys,
        BrickOvenYaml.file,
      );
      return BrickOrError(null, error.message);
    }
    return BrickOrError(directories, null);
  }

  /// gets the current working directory
  Directory get cwd {
    return fileSystem.currentDirectory;
  }
}
