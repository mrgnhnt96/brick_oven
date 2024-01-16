import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import 'package:brick_oven/domain/config/file_config.dart';
import 'package:brick_oven/domain/implementations/target_file_impl.dart';
import 'package:brick_oven/domain/interfaces/source.dart';
import 'package:brick_oven/domain/interfaces/target_file.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:brick_oven/utils/should_exclude_path.dart';

/// {@macro source}
class SourceImpl extends Source {
  /// {@macro source}
  const SourceImpl(
    super.path, {
    required super.targetDir,
    required this.excludePaths,
    required this.fileConfigs,
  });

  @override
  String pathFromSource(String path) {
    return p.join(this.path, path);
  }

  @override
  final Iterable<String> excludePaths;

  @override
  final Map<String, FileConfig> fileConfigs;

  @override
  List<String> targetFileConfigs() {
    final localPath = path;

    final dir = di<FileSystem>().directory(localPath);

    if (!dir.existsSync()) {
      return [];
    }

    final files = dir.listSync(recursive: true).whereType<File>();

    final brickFiles = <String>[];

    for (final file in files) {
      brickFiles.add(file.path.replaceFirst(RegExp('$localPath.'), ''));
    }

    return brickFiles;
  }

  @override
  List<TargetFile> combineFiles() {
    final targetFileConfigs = this.targetFileConfigs();

    for (final file in {...fileConfigs.keys}) {
      if (targetFileConfigs.contains(file)) {
        continue;
      }

      di<Logger>()
        ..info('')
        ..warn(
          'The configured file "$file" does not exist',
        );

      fileConfigs.remove(file);
    }

    final result = <String, FileConfig?>{}
      ..addAll({for (final file in targetFileConfigs) file: null})
      ..addAll(fileConfigs);

    final targetFiles = <TargetFile>[];

    for (final filePath in result.keys) {
      final path = p.normalize(filePath);

      if (shouldExcludePath(path, excludePaths)) {
        continue;
      }

      final target = TargetFileImpl(
        result[path],
        sourcePath: p.join(this.path, path),
        targetDir: targetDir,
        pathWithoutSourceDir: path,
      );

      targetFiles.add(target);
    }

    return targetFiles;
  }
}
