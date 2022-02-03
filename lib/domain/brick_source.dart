import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:equatable/equatable.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class BrickSource extends Equatable {
  const BrickSource({
    required this.localPath,
  }) : fileSystem = const LocalFileSystem();

  factory BrickSource.fromString(String value) {
    return BrickSource(localPath: value);
  }

  @visibleForTesting
  BrickSource.memory({
    required this.localPath,
    FileSystem? fileSystem,
  }) : fileSystem = fileSystem ?? MemoryFileSystem();

  const BrickSource.none()
      : localPath = null,
        fileSystem = const LocalFileSystem();

  factory BrickSource.fromYaml(YamlValue yaml) {
    if (yaml.isString()) {
      return BrickSource.fromString(yaml.asString().value);
    }

    BrickSource handleYaml(YamlMap yaml) {
      final data = yaml.value;

      final localPath = data.remove('path') as String?;

      if (data.isNotEmpty) {
        throw ArgumentError('Unknown keys in source: ${data.keys}');
      }

      return BrickSource(localPath: localPath);
    }

    if (yaml.isYaml()) {
      return handleYaml(yaml.asYaml().value);
    }

    return const BrickSource.none();
  }

  final String? localPath;
  final FileSystem fileSystem;

  Iterable<BrickFile> files() sync* {
    if (localPath != null) {
      yield* _fromDir();
    }
  }

  String get sourceDir {
    if (localPath == null) {
      return '';
    }

    return localPath!;
  }

  Iterable<BrickFile> mergeFilesAndConfig(Iterable<BrickFile> configFiles) {
    final configs = configFiles.toMap();

    final sourceFiles = files().toMap();

    final result = <String, BrickFile>{}
      ..addAll(sourceFiles)
      ..addAll(configs);

    return result.values;
  }

  Iterable<BrickFile> _fromDir() sync* {
    final localPath = this.localPath;
    if (localPath == null) {
      throw Exception('path is null');
    }

    final dir = fileSystem.directory(localPath);

    if (!dir.existsSync()) {
      return;
    }

    final files = dir.listSync(recursive: true)
      ..removeWhere((element) => element is Directory);

    for (final file in files) {
      yield BrickFile(file.path.replaceFirst(RegExp('$localPath.'), ''));
    }
  }

  String fromSourcePath(BrickFile file) {
    return join(sourceDir, file.path);
  }

  @override
  List<Object?> get props => [localPath];
}

extension on Iterable<BrickFile> {
  Map<String, BrickFile> toMap() {
    return fold<Map<String, BrickFile>>(
      <String, BrickFile>{},
      (Map<String, BrickFile> map, BrickFile file) {
        map[file.path] = file;
        return map;
      },
    );
  }
}
