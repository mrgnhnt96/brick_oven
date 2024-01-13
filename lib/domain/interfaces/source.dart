import 'package:brick_oven/domain/interfaces/target_file.dart';
import 'package:brick_oven/domain/config/file_config.dart';

/// {@template source}
/// The base class for where a brick is sourced from
/// {@endtemplate}
abstract class Source {
  /// {@macro source}
  const Source(
    this.path, {
    required this.targetDir,
  });

  /// The path to the source
  final String path;

  /// where the source files are copied to
  final String targetDir;

  /// The paths to exclude from the source
  Iterable<String> get excludePaths;

  /// The files that are has been configured and need
  /// to be cooked
  Map<String, FileConfig> get fileConfigs;

  /// Returns the path to the source file
  String pathFromSource(String path);

  /// returns all paths from source, mapped to the
  List<String> targetFileConfigs();

  /// returns all [targetFileConfigs] and [fileConfigs]
  List<TargetFile> combineFiles();
}
