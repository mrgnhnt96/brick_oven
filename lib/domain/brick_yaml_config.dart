import 'package:autoequal/autoequal.dart';
import 'package:brick_oven/domain/brick_yaml_data.dart';
import 'package:brick_oven/domain/yaml_value.dart';
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
  }) : _fileSystem = fileSystem;

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
    final varsRaw = config['vars'] as Map? ?? const {};
    final vars = <String>[];

    for (final variable in varsRaw.keys) {
      vars.add(variable as String);
    }

    return BrickYamlData(
      name: name,
      vars: vars,
    );
  }
}
