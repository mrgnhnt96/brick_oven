import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_path.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:equatable/equatable.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

/// {@template brick}
/// Represents the brick configured in the `brick_oven.yaml` file
/// {@endtemplate}
class Brick extends Equatable {
  /// {@macro brick}
  Brick({
    required this.name,
    required this.source,
    required this.configuredDirs,
    required this.configuredFiles,
    Logger? logger,
  })  : _fileSystem = const LocalFileSystem(),
        logger = logger ?? Logger();

  /// provide
  @visibleForTesting
  Brick.memory({
    required this.name,
    required this.source,
    required this.configuredDirs,
    required this.configuredFiles,
    required FileSystem fileSystem,
    Logger? logger,
  })  : _fileSystem = fileSystem,
        logger = logger ?? Logger();

  Brick._fromYaml({
    required this.name,
    required this.source,
    required this.configuredFiles,
    required this.configuredDirs,
  })  : _fileSystem = const LocalFileSystem(),
        logger = Logger();

  /// parses [yaml]
  factory Brick.fromYaml(String name, YamlMap? yaml) {
    final data = yaml?.data ?? <String, dynamic>{};
    final source = BrickSource.fromYaml(YamlValue.from(data.remove('source')));

    final filesData = data.remove('files') as YamlMap?;
    Iterable<BrickFile> files() sync* {
      if (filesData == null) {
        return;
      }

      for (final entry in filesData.entries) {
        final path = entry.key as String;
        final yaml = entry.value as YamlMap?;

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

        yield BrickPath.fromYaml(path, YamlValue.from(entry.value));
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

  /// the name of the brick
  final String name;

  /// the source of the content that the brick will create
  final BrickSource source;

  /// the configured files that will alter/update the [source] files
  final Iterable<BrickFile> configuredFiles;

  /// the configured directories that will alter/update the paths of the [source] files
  final Iterable<BrickPath> configuredDirs;

  final FileSystem _fileSystem;

  /// the logger
  final Logger logger;

  /// stops watching the directories that impact the brick
  Future<void> stopWatching() async {
    await source.watcher?.stop();
  }

  /// writes the brick's files, from the [source]'s files.
  ///
  /// targets: [output] (bricks) -> [name] -> __brick__
  void cook({String output = 'bricks', bool watch = false}) {
    final done = logger.progress('Writing Brick: $name');

    void putInTheOven() {
      final targetDir = join(
        output,
        name,
        '__brick__',
      );

      final directory = _fileSystem.directory(targetDir);
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }

      final files = source.mergeFilesAndConfig(configuredFiles);
      final count = files.length;

      for (final file in files) {
        file.writeTargetFile(
          targetDir: targetDir,
          sourceFile: _fileSystem.file(source.fromSourcePath(file)),
          configuredDirs: configuredDirs,
          fileSystem: _fileSystem,
        );
      }

      done('$name: $count file${count == 1 ? '' : 's'}');
    }

    final watcher = source.watcher;

    if (watch && watcher != null) {
      watcher
        ..addEvent(putInTheOven)
        ..start();

      if (watcher.hasRun) {
        return;
      }
    }

    putInTheOven();
  }

  @override
  List<Object?> get props => [
        name,
        source,
        configuredFiles.toList(growable: false),
        configuredDirs.toList(growable: false),
      ];
}
