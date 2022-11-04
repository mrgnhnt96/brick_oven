import 'package:autoequal/autoequal.dart';
import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_path.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/brick_yaml_config.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:equatable/equatable.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';

part 'brick.g.dart';

/// {@template brick}
/// Represents the brick configured in the `brick_oven.yaml` file
/// {@endtemplate}
@autoequal
class Brick extends Equatable {
  /// {@macro brick}
  Brick({
    required this.name,
    required this.source,
    this.configuredDirs = const [],
    this.configuredFiles = const [],
    this.configPath,
    this.brickYamlConfig,
    this.excludePaths = const [],
    Logger? logger,
  })  : _fileSystem = const LocalFileSystem(),
        _logger = logger ?? Logger();

  /// provide
  @visibleForTesting
  const Brick.memory({
    required this.name,
    required this.source,
    required FileSystem fileSystem,
    required Logger logger,
    this.configuredDirs = const [],
    this.configuredFiles = const [],
    this.excludePaths = const [],
    this.configPath,
    this.brickYamlConfig,
  })  : _fileSystem = fileSystem,
        _logger = logger;

  Brick._fromYaml({
    required this.name,
    required this.source,
    required this.configuredFiles,
    required this.configuredDirs,
    required this.excludePaths,
    required this.configPath,
    required this.brickYamlConfig,
  })  : _fileSystem = const LocalFileSystem(),
        _logger = Logger();

  /// parses [yaml]
  factory Brick.fromYaml(
    YamlValue yaml,
    String name, {
    String? configPath,
  }) {
    if (yaml.isError()) {
      throw BrickException(
        brick: name,
        reason: yaml.asError().value,
      );
    }

    if (!yaml.isYaml()) {
      throw BrickException(
        brick: name,
        reason: 'Invalid brick configuration',
      );
    }

    final data = {...yaml.asYaml().value};

    late final BrickSource source;
    try {
      source = BrickSource.fromYaml(
        YamlValue.from(data.remove('source')),
        configPath: configPath,
      );
    } on ConfigException catch (e) {
      throw BrickException(brick: name, reason: e.message);
    } catch (_) {
      rethrow;
    }

    final filesData = YamlValue.from(data.remove('files'));

    Iterable<BrickFile> files() sync* {
      if (filesData.isNone()) {
        return;
      }

      if (!filesData.isYaml()) {
        throw FileException(
          file: name,
          reason: '`files` must be of type `Map`',
        );
      }

      for (final entry in filesData.asYaml().value.entries) {
        final path = entry.key as String;
        final yaml = YamlValue.from(entry.value);

        yield BrickFile.fromYaml(yaml, path: path);
      }
    }

    final pathsData = YamlValue.from(data.remove('dirs'));

    Iterable<BrickPath> paths() sync* {
      if (pathsData.isNone()) {
        return;
      }

      if (!pathsData.isYaml()) {
        throw BrickException(
          brick: name,
          reason: '`dirs` must be a of type `Map`',
        );
      }

      for (final entry in pathsData.asYaml().value.entries) {
        final path = entry.key as String;

        yield BrickPath.fromYaml(YamlValue.from(entry.value), path);
      }
    }

    final excludedPaths = YamlValue.from(data.remove('exclude'));

    Iterable<String> exclude() sync* {
      if (excludedPaths.isNone()) {
        return;
      }

      if (!excludedPaths.isList() && !excludedPaths.isString()) {
        throw BrickException(
          brick: name,
          reason: '`exclude` must be a of type `List`or `String`',
        );
      }

      final paths = <YamlValue>[];

      if (excludedPaths.isList()) {
        paths.addAll(excludedPaths.asList().value.map(YamlValue.from));
      } else {
        paths.add(excludedPaths.asString());
      }

      for (final path in paths) {
        if (path.isString()) {
          yield path.asString().value;
        } else {
          final variableError = VariableException(
            variable: 'exclude',
            reason: 'Expected a `String`, got `${path.value}` '
                // ignore: avoid_dynamic_calls
                '(${path.value.runtimeType})',
          );

          throw BrickException(
            brick: name,
            reason: variableError.message,
          );
        }
      }
    }

    final brickConfig = YamlValue.from(data.remove('brick_config'));
    String? brickYamlPath;
    BrickYamlConfig? brickYamlConfig;

    if (brickConfig.isString()) {
      brickYamlPath = brickConfig.asString().value;
    } else if (brickConfig.isNone()) {
      brickYamlPath = null;
    } else {
      throw BrickException(
        brick: name,
        reason: '`brick_config` must be a of type `String`',
      );
    }

    if (brickYamlPath != null) {
      final dir = BrickPath.cleanPath(dirname(configPath ?? ''));
      brickYamlConfig = BrickYamlConfig(path: join(dir, brickYamlPath));
    }

    if (data.isNotEmpty) {
      throw BrickException(
        brick: name,
        reason: 'Unknown keys: "${data.keys.join('", "')}"',
      );
    }

    return Brick._fromYaml(
      configuredFiles: files().toList(),
      source: source,
      name: name,
      configuredDirs: paths().toList(),
      excludePaths: exclude().toList(),
      configPath: configPath,
      brickYamlConfig: brickYamlConfig,
    );
  }

  /// the name of the brick
  final String name;

  /// the source of the content that the brick will create
  final BrickSource source;

  /// the config file to the brick.yaml file
  ///
  /// When provided, extra checks are performed to ensure the brick.yaml file is
  /// in sync with the brick_oven.yaml file
  final BrickYamlConfig? brickYamlConfig;

  /// the configured files that will alter/update the [source] files
  final List<BrickFile> configuredFiles;

  /// the configured directories that will alter/update the paths of the [source] files
  final List<BrickPath> configuredDirs;

  /// paths to be excluded from the [source]
  final List<String> excludePaths;

  /// if the brick has its own path
  final String? configPath;

  @ignoreAutoequal
  final FileSystem _fileSystem;

  @ignoreAutoequal
  final Logger _logger;

  /// writes the brick's files, from the [source]'s files.
  ///
  /// targets: [output] (bricks) -> [name] -> __brick__
  void cook({String output = 'bricks', bool watch = false}) {
    final done = _logger.progress('Writing Brick: $name');

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

      final files = source.mergeFilesAndConfig(
        configuredFiles,
        excludedPaths: excludePaths,
        logger: _logger,
      );
      final count = files.length;

      for (final file in files) {
        file.writeTargetFile(
          targetDir: targetDir,
          sourceFile: _fileSystem.file(source.fromSourcePath(file)),
          configuredDirs: configuredDirs,
          fileSystem: _fileSystem,
          logger: _logger,
        );
      }

      done.complete('$name: $count file${count == 1 ? '' : 's'} cooked');
    }

    final watcher = source.watcher;

    if (watch && watcher != null) {
      watcher
        ..addEvent(() {
          putInTheOven();
          checkBrickYamlConfig();
        })
        ..start();

      if (watcher.hasRun) {
        return;
      }
    }

    putInTheOven();
    checkBrickYamlConfig();
  }

  /// checks the brick.yaml file to ensure it is in
  /// sync with the brick_oven.yaml file
  void checkBrickYamlConfig() {
    final config = brickYamlConfig;
    if (config == null) {
      return;
    }

    final done = _logger.progress('Checking brick.yaml config');

    final variables = <String>{};

    for (final file in configuredFiles) {
      final names = file.variables.map((e) => e.name);
      variables.addAll(names);
    }

    for (final dir in configuredDirs) {
      variables.add(dir.name.value);
    }

    final data = config.data();

    if (data == null) {
      done.fail("Something went wrong, couldn't read the brick.yaml file");
      return;
    }

    if (data.name != name) {
      _logger.warn(
        '`name` (${data.name}) in brick.yaml does not '
        'match the brick name ($name)',
      );
    }

    final variablesInBrickYaml = data.vars.toSet();

    var couldUseAttention = false;

    if (variablesInBrickYaml.difference(variables).isNotEmpty) {
      _logger.warn(
        '\nThe following variables are defined in brick.yaml but not used in '
        'brick_oven.yaml: '
        '"${variablesInBrickYaml.difference(variables).join('", "')}"\n',
      );
      couldUseAttention = true;
    }

    if (variables.difference(variablesInBrickYaml).isNotEmpty) {
      _logger.warn(
        'The following variables are defined in '
        'brick_oven.yaml but not used in '
        'brick.yaml:\n'
        '"${variables.difference(variablesInBrickYaml).join('", "')}"',
      );
      couldUseAttention = true;
    }

    if (couldUseAttention) {
      done.fail('$name: brick.yaml needs attention');
    } else {
      done.complete('$name: brick.yaml is in sync');
    }
  }

  @override
  List<Object?> get props => _$props;
}
