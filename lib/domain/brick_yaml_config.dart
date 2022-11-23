import 'package:autoequal/autoequal.dart';
import 'package:brick_oven/domain/brick_dir.dart';
import 'package:brick_oven/domain/brick_yaml_data.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/extensions/yaml_map_extensions.dart';
import 'package:equatable/equatable.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

part 'brick_yaml_config.g.dart';

/// {@template brick_yaml_config}
/// Represents the configurations for the brick within the `brick.yaml` file
/// {@endtemplate}
@autoequal
class BrickYamlConfig extends Equatable {
  /// {@macro brick_yaml_config}
  const BrickYamlConfig({
    required this.path,
    required FileSystem fileSystem,
    required this.ignoreVars,
  }) : _fileSystem = fileSystem;

  /// {@macro brick_yaml_config}
  factory BrickYamlConfig.fromYaml(
    YamlValue yaml, {
    required FileSystem fileSystem,
  }) {
    if (yaml.isError()) {
      throw BrickConfigException(reason: yaml.asError().value);
    }

    if (yaml.isString()) {
      final path = yaml.asString().value;

      return BrickYamlConfig(
        path: path,
        fileSystem: fileSystem,
        ignoreVars: const [],
      );
    }

    if (!yaml.isYaml()) {
      throw const BrickConfigException(
        reason: '`brick_config` must be a of type `String` or `Map`',
      );
    }

    final data = yaml.asYaml().value.data;

    final path = YamlValue.from(data.remove('path'));
    if (!path.isString()) {
      throw const BrickConfigException(
        reason: '`brick_config.path` must be a of type `String`',
      );
    }

    final ignoreVars = <String>[];

    final ignoreVarsData = YamlValue.from(data.remove('ignore_vars'));
    if (ignoreVarsData.isList()) {
      final vars = List<String>.from(ignoreVarsData.asList().value);
      ignoreVars.addAll(vars);
    } else if (!ignoreVarsData.isNone()) {
      throw const BrickConfigException(
        reason: '`brick_config.ignore_vars` must be a of type `List`',
      );
    }

    if (data.isNotEmpty) {
      throw BrickConfigException(
        reason: 'Unknown keys: "${data.keys.join('", "')}"',
      );
    }

    final dir = BrickDir.cleanPath(path.asString().value);

    return BrickYamlConfig(
      path: dir,
      ignoreVars: ignoreVars,
      fileSystem: fileSystem,
    );
  }

  /// a list of variables that will not be checked for sync
  ///
  /// This includes
  /// - if the variable exists in the brick.yaml file but not brick_oven.yaml
  /// - if the variable exists in brick_oven.yaml but not brick.yaml
  final List<String> ignoreVars;

  /// the path to the brick.yaml file
  final String path;

  @ignoreAutoequal
  final FileSystem _fileSystem;

  @override
  List<Object?> get props => _$props;

  /// the data within the brick.yaml file
  // ignore: library_private_types_in_public_api
  BrickYamlData? data({required Logger logger}) {
    final file = _fileSystem.file(path);

    if (!file.existsSync()) {
      logger.warn('`brick.yaml` not found at $path');
      return null;
    }

    final yaml = YamlValue.from(loadYaml(file.readAsStringSync()));

    if (!yaml.isYaml()) {
      logger.warn('Error reading `brick.yaml`');
      return null;
    }

    final config = Map<String, dynamic>.from(yaml.asYaml().value);

    final name = config['name'] as String? ?? 'Unknown';
    final varsRaw = YamlValue.from(config['vars']);
    final vars = <String>[];

    // legacy support for `vars` as a list
    if (varsRaw.isList()) {
      vars.addAll(List<String>.from(varsRaw.asList().value));

      return BrickYamlData(
        name: name,
        vars: vars,
      );
    }

    if (varsRaw.isNone()) {
      return BrickYamlData(
        name: name,
        vars: vars,
      );
    }

    if (!varsRaw.isYaml()) {
      logger.warn('`vars` is an unsupported type in `brick.yaml`');

      return BrickYamlData(
        name: name,
        vars: vars,
      );
    }

    for (final variable in varsRaw.asYaml().value.keys) {
      vars.add(variable as String);
    }

    return BrickYamlData(
      name: name,
      vars: vars,
    );
  }
}
