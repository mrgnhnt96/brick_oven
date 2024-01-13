import 'package:args/command_runner.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';

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
}
