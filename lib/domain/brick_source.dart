import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:equatable/equatable.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

/// {@template brick_source}
/// The brick's source, where the files are retrived, copied &/or altered
/// {@endtemplate}
class BrickSource extends Equatable {
  /// {@macro brick_source}
  BrickSource({
    required this.localPath,
  })  : _fileSystem = const LocalFileSystem(),
        watcher = localPath != null ? BrickWatcher(localPath) : null;

  /// parses the [value] into the appropriate type of source
  factory BrickSource.fromString(String value) {
    return BrickSource(localPath: value);
  }

  /// creates a memory source, avoids writing files to machine/locally
  @visibleForTesting
  BrickSource.memory({
    required this.localPath,
    FileSystem? fileSystem,
    this.watcher,
  }) : _fileSystem = fileSystem ?? MemoryFileSystem();

  /// creates and empty source
  const BrickSource.none()
      : localPath = null,
        _fileSystem = const LocalFileSystem(),
        watcher = null;

  /// parse [yaml] into the source
  factory BrickSource.fromYaml(YamlValue yaml) {
    if (yaml.isString()) {
      return BrickSource.fromString(yaml.asString().value);
    }

    BrickSource handleYaml(YamlMap yaml) {
      final data = yaml.data;

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

  /// the local path of the source files
  final String? localPath;
  final FileSystem _fileSystem;

  /// Watches the local files, and updates on events
  final BrickWatcher? watcher;

  /// retrieves the files from the source path
  Iterable<BrickFile> files() sync* {
    if (localPath != null) {
      yield* _fromDir();
      return;
    }
  }

  /// the directory of the source
  String get sourceDir {
    if (localPath == null) {
      return '';
    }

    return localPath!;
  }

  /// merges the [configFiles] onto [files], which copies all
  /// variables & configurations
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

    final dir = _fileSystem.directory(localPath);

    if (!dir.existsSync()) {
      return;
    }

    final files = dir.listSync(recursive: true)
      ..removeWhere((element) => element is Directory);

    for (final file in files) {
      yield BrickFile(file.path.replaceFirst(RegExp('$localPath.'), ''));
    }
  }

  /// returns the path of [file] as if it were from the [sourceDir]
  String fromSourcePath(BrickFile file) {
    return join(sourceDir, file.path);
  }

  @override
  List<Object?> get props => [localPath];
}

extension on Iterable<BrickFile> {
  Map<String, BrickFile> toMap() {
    return {for (final val in this) val.path: val};
  }
}
