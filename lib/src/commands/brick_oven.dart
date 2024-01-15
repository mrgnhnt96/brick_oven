import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';

import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/domain/config/brick_oven_config.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:brick_oven/utils/yaml_to_json.dart';

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

  BrickOvenConfig? getBrickOvenConfig() {
    final configFile = BrickOvenYaml.findNearest(cwd);

    if (configFile == null) {
      return null;
    }

    final json = YamlToJson.fromFile(configFile);

    try {
      return BrickOvenConfig.fromJson(json, configPath: configFile.path);
    } catch (e) {
      // do nothing
    }

    return null;
  }
}
