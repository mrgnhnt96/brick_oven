import 'package:autoequal/autoequal.dart';
import 'package:equatable/equatable.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

import 'package:brick_oven/domain/brick_dir.dart';
import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/source_watcher.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/extensions/yaml_map_extensions.dart';

part 'brick_source.g.dart';

/// {@template brick_source}
/// The brick's source, where the files are retrieved, copied &/or altered
/// {@endtemplate}
@autoequal
class BrickSource extends Equatable {
  /// {@macro brick_source}
  BrickSource({
    required this.localPath,
    required FileSystem fileSystem,
  })  : _fileSystem = fileSystem,
        watcher = localPath != null ? SourceWatcher(localPath) : null;

  /// parses the [value] into the appropriate type of source
  factory BrickSource.fromString(
    String value, {
    required FileSystem fileSystem,
  }) {
    return BrickSource(
      localPath: value,
      fileSystem: fileSystem,
    );
  }

  /// parse [yaml] into the source
  factory BrickSource.fromYaml(
    YamlValue yaml, {
    required FileSystem fileSystem,
    String? configPath,
  }) {
    if (yaml.isError()) {
      throw const SourceException(
        source: '??',
        reason: 'Invalid brick source',
      );
    }

    final configDir = dirname(configPath ?? '');

    if (yaml.isString()) {
      final path = BrickDir.cleanPath(join(configDir, yaml.asString().value));

      return BrickSource.fromString(
        path,
        fileSystem: fileSystem,
      );
    }

    BrickSource handleYaml(YamlMap yaml) {
      final data = yaml.data;

      final localPath = YamlValue.from(data.remove('path'));

      if (localPath.isNone()) {
        final path = BrickDir.cleanPath(configDir);
        if (path.isEmpty) {
          return BrickSource.none(fileSystem: fileSystem);
        }

        throw SourceException(
          source: path,
          reason: '`source` value is required in sub config files',
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

      final path =
          BrickDir.cleanPath(join(configDir, localPath.asString().value));

      if (path.isEmpty) {
        return BrickSource.none(fileSystem: fileSystem);
      }

      return BrickSource.fromString(
        path,
        fileSystem: fileSystem,
      );
    }

    if (yaml.isYaml()) {
      return handleYaml(yaml.asYaml().value);
    }

    final path = BrickDir.cleanPath(configDir);

    if (path.isEmpty) {
      return BrickSource.none(fileSystem: fileSystem);
    }

    throw SourceException(
      source: path,
      reason: '`source` value is required in sub config files',
    );
  }

  /// creates a memory source, avoids writing files to machine/locally
  @visibleForTesting
  const BrickSource.memory({
    required this.localPath,
    required FileSystem fileSystem,
    this.watcher,
  }) : _fileSystem = fileSystem;

  /// creates and empty source
  const BrickSource.none({
    required FileSystem fileSystem,
  })  : localPath = null,
        _fileSystem = fileSystem,
        watcher = null;

  /// the local path of the source files
  final String? localPath;

  /// Watches the local files, and updates on events
  final SourceWatcher? watcher;

  @ignoreAutoequal
  final FileSystem _fileSystem;

  @override
  List<Object?> get props => _$props;

  /// the directory of the source
  String get sourceDir {
    if (localPath == null) {
      return '';
    }

    return localPath!;
  }

  /// returns the path of [path] as if it were from the [sourceDir]
  String fromSourcePath(String path) {
    return join(sourceDir, path);
  }

  /// merges the [configFiles] onto [files], which copies all
  /// variables & configurations
  Iterable<BrickFile> mergeFilesAndConfig(
    Iterable<BrickFile> configFiles, {
    required Logger logger,
    Iterable<String> excludedPaths = const [],
  }) {
    final configs = configFiles.toMap();

    final sourceFiles = files().toMap();

    final keys = configs.keys;
    final keysToRemove = <String>{};
    for (final file in keys) {
      if (sourceFiles.containsKey(file)) {
        continue;
      }

      logger
        ..info('')
        ..warn(
          'The configured file "$file" does not exist within $sourceDir',
        );

      keysToRemove.add(file);
    }

    for (final key in keysToRemove) {
      configs.remove(key);
    }

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

  /// retrieves the files from the [localPath] directory
  List<BrickFile> files() {
    final localPath = this.localPath;

    if (localPath == null) {
      return [];
    }

    final dir = _fileSystem.directory(localPath);

    if (!dir.existsSync()) {
      return [];
    }

    final files = dir.listSync(recursive: true).whereType<File>();

    final brickFiles = <BrickFile>[];

    for (final file in files) {
      final brickFile = BrickFile(
        file.path.replaceFirst(RegExp('$localPath.'), ''),
      );

      brickFiles.add(brickFile);
    }

    return brickFiles;
  }
}

extension on Iterable<BrickFile> {
  Map<String, BrickFile> toMap() {
    return {for (final val in this) val.path: val};
  }
}
