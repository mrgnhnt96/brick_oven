import 'package:autoequal/autoequal.dart';
import 'package:brick_oven/utils/di.dart';
import 'package:equatable/equatable.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';

import 'package:brick_oven/domain/brick_dir.dart';
import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/brick_url.dart';
import 'package:brick_oven/domain/brick_yaml_config.dart';
import 'package:brick_oven/domain/file_write_result.dart';
import 'package:brick_oven/domain/partial.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/constants.dart';
import 'package:brick_oven/utils/extensions/yaml_map_extensions.dart';

part 'brick.g.dart';

/// {@template brick}
/// Represents the brick configured in the `brick_oven.yaml` file
/// {@endtemplate}
@autoequal
class Brick extends Equatable {
  /// {@macro brick}
  const Brick({
    required this.name,
    required this.source,
    this.dirs = const [],
    this.files = const [],
    this.partials = const [],
    this.configPath,
    this.brickYamlConfig,
    this.exclude = const [],
    this.urls = const [],
  });

  const Brick._fromYaml({
    required this.name,
    required this.source,
    required this.files,
    required this.dirs,
    required this.exclude,
    required this.configPath,
    required this.brickYamlConfig,
    required this.partials,
    required this.urls,
  });

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

    final data = yaml.asYaml().value.data;

    late final BrickSource source;
    try {
      source = BrickSource.fromYaml(
        YamlValue.from(data.remove('source')),
        configPath: configPath,
      );
    } on ConfigException catch (e) {
      throw BrickException(
        brick: name,
        reason: e.message,
      );
    } catch (e) {
      throw BrickException(
        brick: name,
        reason: e.toString(),
      );
    }

    final filesData = YamlValue.from(data.remove('files'));

    List<BrickFile> files() {
      final files = <BrickFile>[];

      if (filesData.isNone()) {
        return files;
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

        final file = BrickFile.fromYaml(yaml, path: path);
        files.add(file);
      }

      return files;
    }

    final pathsData = YamlValue.from(data.remove('dirs'));

    List<BrickDir> paths() {
      final paths = <BrickDir>[];

      if (pathsData.isNone()) {
        return paths;
      }

      if (!pathsData.isYaml()) {
        throw BrickException(
          brick: name,
          reason: '`dirs` must be a of type `Map`',
        );
      }

      for (final entry in pathsData.asYaml().value.entries) {
        final path = entry.key as String;

        final dir = BrickDir.fromYaml(YamlValue.from(entry.value), path);
        paths.add(dir);
      }

      return paths;
    }

    final partialsData = YamlValue.from(data.remove('partials'));

    List<Partial> partials() {
      if (partialsData.isNone()) {
        return [];
      }

      if (!partialsData.isYaml()) {
        throw BrickException(
          brick: name,
          reason: '`partials` must be a of type `Map`',
        );
      }

      final partials = <Partial>[];

      for (final entry in partialsData.asYaml().value.entries) {
        final path = entry.key as String;

        final partial = Partial.fromYaml(
          YamlValue.from(entry.value),
          path,
        );

        partials.add(partial);
      }

      return partials;
    }

    final excludedPaths = YamlValue.from(data.remove('exclude'));

    List<String> exclude() {
      final excludes = <String>[];

      if (excludedPaths.isNone()) {
        return excludes;
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
          excludes.add(path.asString().value);
          continue;
        }

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

      return excludes;
    }

    final urlData = YamlValue.from(data.remove('urls'));

    List<BrickUrl> urls() {
      final urls = <BrickUrl>[];

      if (urlData.isNone()) {
        return urls;
      }

      if (!urlData.isYaml()) {
        throw BrickException(
          brick: name,
          reason: '`urls` must be a of type `Map`',
        );
      }

      for (final entry in urlData.asYaml().value.entries) {
        final path = entry.key as String;

        final url = BrickUrl.fromYaml(YamlValue.from(entry.value), path);

        urls.add(url);
      }

      return urls;
    }

    final brickConfig = YamlValue.from(data.remove('brick_config'));
    BrickYamlConfig? brickYamlConfig;

    if (!brickConfig.isNone()) {
      brickYamlConfig = BrickYamlConfig.fromYaml(
        brickConfig,
        configPath: dirname(configPath ?? ''),
      );
    }

    if (data.isNotEmpty) {
      throw BrickException(
        brick: name,
        reason: 'Unknown keys: "${data.keys.join('", "')}"',
      );
    }

    return Brick._fromYaml(
      files: files(),
      partials: partials(),
      dirs: paths(),
      exclude: exclude(),
      urls: urls(),
      source: source,
      name: name,
      configPath: configPath,
      brickYamlConfig: brickYamlConfig,
    );
  }

  /// the config file to the brick.yaml file
  ///
  /// When provided, extra checks are performed to ensure the brick.yaml file is
  /// in sync with the brick_oven.yaml file
  final BrickYamlConfig? brickYamlConfig;

  /// The path of the configuration for this brick if it is not
  /// configured within the [BrickOvenYaml.file]
  final String? configPath;

  /// the configured directories that will alter/update the paths of the [source] files
  final List<BrickDir> dirs;

  /// the configured files that will alter/update the [source] files
  final List<BrickFile> files;

  /// the configured partials that will be imported to the [source] files
  final List<Partial> partials;

  /// the configured urls that will be imported to the [source] files
  final List<BrickUrl> urls;

  /// paths to be excluded from the [source]
  final List<String> exclude;

  /// the name of the brick
  final String name;

  /// the source of the content that the brick will create
  final BrickSource source;

  /// variables used not provided by the user
  static List<Variable> get defaultVariables => [
        const Variable(name: '.', placeholder: kIndexValue),
      ];

  @override
  List<Object?> get props => _$props;

  /// returns the variables within brick
  ///
  /// pulls from
  /// - [files]
  ///   - [BrickFile.variables]
  /// - [dirs]
  ///   - [BrickDir.name]
  ///   - [BrickDir.includeIf]
  ///   - [BrickDir.includeIfNot]
  Set<String> allBrickVariables() {
    final rawVariables = <String>{};

    for (final file in files) {
      final names = file.variables.map((e) => e.name);
      rawVariables.addAll(names);

      if (file.includeIf != null) {
        rawVariables.add(file.includeIf!);
      }

      if (file.includeIfNot != null) {
        rawVariables.add(file.includeIfNot!);
      }

      if (file.name != null) {
        rawVariables.addAll(file.name!.variables);
      }
    }

    for (final partial in partials) {
      final names = partial.variables.map((e) => e.name);
      rawVariables.addAll(names);
    }

    for (final dir in dirs) {
      if (dir.name != null) {
        rawVariables.addAll(dir.name!.variables);
      }

      if (dir.includeIf != null) {
        rawVariables.add(dir.includeIf!);
      }

      if (dir.includeIfNot != null) {
        rawVariables.add(dir.includeIfNot!);
      }
    }

    for (final url in urls) {
      rawVariables.addAll(url.variables);
    }

    final variables = <String>{};

    for (final variable in rawVariables) {
      if (variable.contains('.') && variable != '.') {
        variables.add(variable.split('.').first);
      } else {
        variables.add(variable);
      }
    }

    return variables;
  }

  /// checks the brick.yaml file to ensure it is in
  /// sync with the brick_oven.yaml file
  void checkBrickYamlConfig({required bool shouldSync}) {
    if (!shouldSync) {
      return;
    }

    final config = brickYamlConfig;
    if (config == null) {
      return;
    }

    final brickYaml = config.data;

    if (brickYaml == null) {
      return;
    }

    final brickOvenFileName = configPath ?? BrickOvenYaml.file;

    var isInSync = true;

    if (brickYaml.name != name) {
      isInSync = false;
      di<Logger>().warn(
        '`name` (${brickYaml.name}) in brick.yaml does not '
        'match the name in $brickOvenFileName ($name)',
      );
    }

    final alwaysRemove = [kIndexValue, '.', ...config.ignoreVars];

    final variables = allBrickVariables()..removeAll(alwaysRemove);

    final variablesInBrickYaml = brickYaml.vars.toSet()
      ..removeAll(alwaysRemove);

    if (variablesInBrickYaml.difference(variables).isNotEmpty) {
      isInSync = false;
      final vars =
          '"${variablesInBrickYaml.difference(variables).join('", "')}"';
      di<Logger>().warn(
        'Variables ($vars) exist in brick.yaml but not in $brickOvenFileName',
      );
    }

    if (variables.difference(variablesInBrickYaml).isNotEmpty) {
      isInSync = false;
      final vars =
          '"${variables.difference(variablesInBrickYaml).join('", "')}"';

      di<Logger>().warn(
        'Variables ($vars) exist in $brickOvenFileName but not in brick.yaml',
      );
    }

    if (isInSync) {
      di<Logger>().info(darkGray.wrap('brick.yaml is in sync'));
    } else {
      di<Logger>().err('brick.yaml is out of sync');
    }
  }

  /// writes the brick's files, from the [source]'s files.
  ///
  /// targets: [output] (bricks) -> [name] -> __brick__
  void cook({
    String? output,
    bool watch = false,
    bool shouldSync = true,
  }) {
    output ??= 'bricks';

    final targetDir = join(output, name, '__brick__');

    final names = <String>{};

    for (final partial in partials) {
      if (names.contains(partial.fileName)) {
        throw BrickException(
          brick: name,
          reason: 'Duplicate partials ("${partial.fileName}") in $name',
        );
      }

      names.add(partial.fileName);
    }

    final done = di<Logger>().progress('Writing Brick: $name');

    final excludedPaths = [...exclude, '__brick__', 'bricks', '.git'];

    if (output != '.') {
      excludedPaths.add(output);
    }

    final watcher = source.watcher;

    if (watch && watcher != null) {
      watcher
        ..addEvent(
          (_) => _putInTheOven(
            targetDir: targetDir,
            done: done,
            excludedPaths: excludedPaths.toSet(),
          ),
        )
        ..addEvent((_) => checkBrickYamlConfig(shouldSync: shouldSync))
        ..start(excludedPaths);

      if (watcher.hasRun) {
        return;
      }
    }

    _putInTheOven(
      targetDir: targetDir,
      done: done,
      excludedPaths: excludedPaths.toSet(),
    );
    checkBrickYamlConfig(shouldSync: shouldSync);
  }

  void _fail(Progress progress, String type, String path) {
    progress.fail(
      '${darkGray.wrap('($name)')} '
      'Failed to write $type: $path',
    );
  }

  void _putInTheOven({
    required String targetDir,
    required Progress done,
    required Set<String> excludedPaths,
  }) {
    final directory = di<FileSystem>().directory(targetDir);
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }

    final mergedFiles = source.mergeFilesAndConfig(
      files,
      excludedPaths: excludedPaths,
    );
    final count = mergedFiles.length;

    final usedVariables = <String>{};
    final usedPartials = <String>{};

    final partialPaths = partials.map((e) => e.path).toSet();

    for (final file in mergedFiles) {
      if (partialPaths.contains(file.path)) {
        // skip partial file generation
        continue;
      }

      FileWriteResult writeResult;

      try {
        writeResult = file.writeTargetFile(
          targetDir: targetDir,
          sourceFile: di<FileSystem>().file(source.fromSourcePath(file.path)),
          dirs: dirs,
          partials: partials,
          urls: urls,
          outOfFileVariables: defaultVariables,
        );
      } on ConfigException catch (e) {
        _fail(done, 'file', file.path);

        throw BrickException(
          brick: name,
          reason: e.message,
        );
      } catch (_) {
        _fail(done, 'file', file.path);
        rethrow;
      }

      usedVariables.addAll(writeResult.usedVariables);
      usedPartials.addAll(writeResult.usedPartials);
    }

    for (final partial in partials) {
      FileWriteResult writeResult;
      try {
        writeResult = partial.writeTargetFile(
          targetDir: targetDir,
          sourceFile:
              di<FileSystem>().file(source.fromSourcePath(partial.path)),
          partials: partials,
          outOfFileVariables: defaultVariables,
        );
      } on ConfigException catch (e) {
        _fail(done, 'partial', partial.path);
        throw BrickException(
          brick: name,
          reason: e.message,
        );
      } catch (_) {
        _fail(done, 'partial', partial.path);

        rethrow;
      }

      usedPartials.addAll(writeResult.usedPartials);
      usedVariables.addAll(writeResult.usedVariables);
    }

    final partialNames = partials.map((e) => e.path).toSet();

    final unusedVariables = allBrickVariables().difference(usedVariables);
    final unusedPartials = partialNames.difference(usedPartials);

    if (unusedVariables.isNotEmpty) {
      final vars = '"${unusedVariables.join('", "')}"';
      di<Logger>().warn(
        'Unused variables ($vars) in $name',
      );
    }

    if (unusedPartials.isNotEmpty) {
      final partials = '"${unusedPartials.map(basename).join('", "')}"';
      di<Logger>().warn(
        'Unused partials ($partials) in $name',
      );
    }

    done.complete(
      '${cyan.wrap(name)}: cooked '
      '${yellow.wrap('$count')} file${count == 1 ? '' : 's'}',
    );
  }
}
