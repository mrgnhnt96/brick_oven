import 'package:autoequal/autoequal.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:equatable/equatable.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
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
    FileSystem? fileSystem,
  }) : _fileSystem = fileSystem ?? const LocalFileSystem();

  /// the path to the brick.yaml file
  final String path;

  /// the data within the brick.yaml file
  // ignore: library_private_types_in_public_api
  _Config? data() {
    final file = _fileSystem.file(path);
    final yaml = YamlValue.from(loadYaml(file.readAsStringSync()));

    if (!yaml.isYaml()) {
      return null;
    }

    final config = Map<String, dynamic>.from(yaml.asYaml().value);

    final name = config['name'] as String? ?? 'Unknown';
    final varsRaw = config['vars'] as Map? ?? const {};
    final vars = <String>[];

    for (final variable in varsRaw.keys) {
      vars.add(variable as String);
    }

    return _Config(
      name: name,
      vars: vars,
    );
  }

  @ignoreAutoequal
  final FileSystem _fileSystem;

  @override
  List<Object?> get props => _$props;
}

@autoequal
class _Config extends Equatable {
  const _Config({
    required this.name,
    required this.vars,
  });

  final String name;
  final List<String> vars;

  @override
  List<Object?> get props => _$props;
}