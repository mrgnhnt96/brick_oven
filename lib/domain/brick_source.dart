import 'package:autoequal/autoequal.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
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
import 'package:brick_oven/utils/should_exclude_path.dart';

part 'brick_source.g.dart';

/// {@template brick_source}
/// The brick's source, where the files are retrieved, copied &/or altered
/// {@endtemplate}
@autoequal
class BrickSource extends Equatable {
  /// {@macro brick_source}
  BrickSource({
    required this.localPath,
  }) : watcher = localPath != null ? SourceWatcher(localPath) : null;

  /// parses the [value] into the appropriate type of source
  factory BrickSource.fromString(String value) {
    return BrickSource(
      localPath: value,
    );
  }

  /// parse [yaml] into the source
  factory BrickSource.fromYaml(
    YamlValue yaml, {
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

      return BrickSource.fromString(path);
    }

    BrickSource handleYaml(YamlMap yaml) {
      final data = yaml.data;

      final localPath = YamlValue.from(data.remove('path'));

      if (localPath.isNone()) {
        final path = BrickDir.cleanPath(configDir);
        if (path.isEmpty) {
          return const BrickSource.none();
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
        return const BrickSource.none();
      }

      return BrickSource.fromString(path);
    }

    if (yaml.isYaml()) {
      return handleYaml(yaml.asYaml().value);
    }

    final path = BrickDir.cleanPath(configDir);

    if (path.isEmpty) {
      return const BrickSource.none();
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
    this.watcher,
  });

  /// creates and empty source
  const BrickSource.none()
      : localPath = null,
        watcher = null;

  /// the local path of the source files
  final String? localPath;

  /// Watches the local files, and updates on events
  final SourceWatcher? watcher;

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

      di<Logger>()
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

    final brickFiles = <BrickFile>[];

    for (final key in result.keys) {
      final path = normalize(key);

      if (shouldExcludePath(path, excludedPaths)) {
        continue;
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

    final dir = di<FileSystem>().directory(localPath);

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
