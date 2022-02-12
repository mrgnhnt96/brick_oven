import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

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
  Set<Brick> get bricks {
    final configFile = BrickOvenYaml.findNearest(cwd);

    if (configFile == null) {
      throw const BrickOvenNotFoundException();
    }

    final config = loadYaml(configFile.readAsStringSync()) as YamlMap;

    final directories = <Brick>{};

    final data = config.data;

    final bricks = data.remove('bricks') as YamlMap?;

    if (bricks != null) {
      for (final brick in bricks.entries) {
        final name = brick.key as String;
        final value = brick.value as YamlMap?;

        directories.add(Brick.fromYaml(name, value));
      }
    }

    if (data.keys.isNotEmpty) {
      throw UnknownKeysException(
        data.keys,
        BrickOvenYaml.file,
      );
    }

    return directories;
  }

  /// gets the current working directory
  Directory get cwd {
    return fileSystem.currentDirectory;
  }
}
