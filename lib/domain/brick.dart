import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_path.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:equatable/equatable.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class Brick extends Equatable {
  const Brick({
    required this.name,
    required this.source,
    required this.configuredDirs,
    required this.configuredFiles,
  }) : fileSystem = const LocalFileSystem();

  @visibleForTesting
  Brick.memory({
    required this.name,
    required this.source,
    required this.configuredDirs,
    required this.configuredFiles,
    required FileSystem? fileSystem,
  }) : fileSystem = fileSystem ?? MemoryFileSystem();

  const Brick._fromYaml({
    required this.name,
    required this.source,
    required this.configuredFiles,
    required this.configuredDirs,
  }) : fileSystem = const LocalFileSystem();

  factory Brick.fromYaml(String name, YamlMap yaml) {
    final data = yaml.value;
    final source = BrickSource.fromYaml(data.remove('source'));

    final filesData = data.remove('files') as YamlMap?;
    Iterable<BrickFile> files() sync* {
      if (filesData == null) {
        return;
      }

      for (final entry in filesData.entries) {
        final path = entry.key as String;
        final yaml = entry.value as YamlMap;

        yield BrickFile.fromYaml(yaml, path: path);
      }
    }

    final pathsData = data.remove('dirs') as YamlMap?;

    Iterable<BrickPath> paths() sync* {
      if (pathsData == null) {
        return;
      }

      for (final entry in pathsData.entries) {
        final path = entry.key as String;

        yield BrickPath.fromYaml(path, entry.value);
      }
    }

    if (data.isNotEmpty) {
      throw ArgumentError('Unknown keys in brick: ${data.keys}');
    }

    return Brick._fromYaml(
      configuredFiles: files(),
      source: source,
      name: name,
      configuredDirs: paths(),
    );
  }

  final String name;
  final BrickSource source;
  final Iterable<BrickFile> configuredFiles;
  final Iterable<BrickPath> configuredDirs;
  final FileSystem fileSystem;

  void writeBrick() {
    final targetDir = join(
      'bricks',
      name,
      '__brick__',
    );

    final directory = fileSystem.directory(targetDir);
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }

    for (final file in source.mergeFilesAndConfig(configuredFiles)) {
      file.writeTargetFile(
        targetDir: targetDir,
        sourceFile: fileSystem.file(source.fromSourcePath(file)),
        configuredDirs: configuredDirs,
        fileSystem: fileSystem,
      );
    }
  }

  @override
  List<Object?> get props => [
        name,
        source,
        configuredFiles.toList(),
        configuredDirs.toList(),
      ];
}
