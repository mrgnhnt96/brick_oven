import 'package:autoequal/autoequal.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:equatable/equatable.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/utils/extensions.dart';

part 'brick_source.g.dart';

/// {@template brick_source}
/// The brick's source, where the files are retrived, copied &/or altered
/// {@endtemplate}
@autoequal
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
  factory BrickSource.fromYaml(
    YamlValue yaml, {
    String? configPath,
  }) {
    final configDir = dirname(configPath ?? '');

    if (yaml.isString()) {
      final path = join(configDir, yaml.asString().value).cleanUpPath();

      return BrickSource.fromString(path);
    }

    BrickSource handleYaml(YamlMap yaml) {
      final data = yaml.data;

      final localPath = YamlValue.from(data.remove('path'));

      if (localPath.isNone()) {
        final path = configDir.cleanUpPath();
        if (path.isEmpty) {
          return const BrickSource.none();
        }

        throw SourceException(
          source: path,
          reason: 'Source path is required in sub config files',
        );
      }

      if (!localPath.isString()) {
        throw const SourceException(
          source: '??',
          reason: 'Must contain a `path` key with a string value',
        );
      }

      if (data.isNotEmpty) {
        throw SourceException(
          source: localPath.asString().value,
          reason: 'Unknown keys: "${data.keys.join('", "')}"',
        );
      }

      final path = join(configDir, localPath.asString().value).cleanUpPath();

      if (path.isEmpty) {
        return const BrickSource.none();
      }

      return BrickSource.fromString(path);
    }

    if (yaml.isYaml()) {
      return handleYaml(yaml.asYaml().value);
    }

    final path = configDir.cleanUpPath();

    if (path.isEmpty) {
      return const BrickSource.none();
    }

    throw SourceException(
      source: path,
      reason: 'Source path is required in sub config files',
    );
  }

  /// the local path of the source files
  final String? localPath;

  @ignoreAutoequal
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
  Iterable<BrickFile> mergeFilesAndConfig(
    Iterable<BrickFile> configFiles, {
    Iterable<String> excludedPaths = const [],
  }) {
    final configs = configFiles.toMap();

    final sourceFiles = files().toMap();

    final result = <String, BrickFile>{}
      ..addAll(sourceFiles)
      ..addAll(configs);

    final excludedDirs = <String>[];
    final excludedFiles = <String>[];

    for (final e in excludedPaths) {
      final path = normalize(e);

      if (extension(path).isNotEmpty) {
        excludedFiles.add(path);
      } else {
        excludedDirs.add(path);
      }
    }

    final brickFiles = <BrickFile>[];

    for (final key in result.keys) {
      final path = normalize(key);

      if (excludedFiles.contains(path)) {
        break;
      }

      if (excludedDirs.any(path.startsWith)) {
        break;
      }

      brickFiles.add(result[key]!);
    }

    return brickFiles;
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
  List<Object?> get props => _$props;
}

extension on Iterable<BrickFile> {
  Map<String, BrickFile> toMap() {
    return {for (final val in this) val.path: val};
  }
}

extension _StringX on String {
  String cleanUpPath() {
    String removeLast(String path) {
      if (path.endsWith('/') || path.endsWith('.')) {
        return removeLast(path.substring(0, path.length - 1));
      }

      return path;
    }

    var str = normalize(this);

    if (this == './') {
      return '';
    } else if (startsWith('./')) {
      str = substring(2);
    }

    return str = removeLast(str);
  }
}
