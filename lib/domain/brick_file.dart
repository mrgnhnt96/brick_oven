import 'package:brick_oven/domain/brick_path.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_format.dart';
import 'package:brick_oven/enums/mustache_loops.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:equatable/equatable.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' hide extension;
import 'package:path/path.dart' as p show extension;
import 'package:yaml/yaml.dart';

class BrickFile extends Equatable {
  const BrickFile(this.path)
      : variables = const [],
        prefix = null,
        suffix = null,
        name = null;

  const BrickFile._fromYaml(
    this.path, {
    required this.variables,
    required this.prefix,
    required this.suffix,
    required this.name,
  });

  @visibleForTesting
  const BrickFile.config(
    this.path, {
    this.variables = const [],
    this.prefix,
    this.suffix,
    this.name,
  });

  factory BrickFile.fromYaml(
    YamlMap? yaml, {
    required String path,
  }) {
    if (yaml == null) {
      throw ArgumentError(
        'There are not any configurations for $path, '
        'please remove it or add congfiguration',
      );
    }

    final data = yaml.data;

    final variablesData = data.remove('vars') as YamlMap?;

    Iterable<Variable> variables() sync* {
      if (variablesData == null) {
        return;
      }

      for (final entry in variablesData.entries) {
        final name = entry.key as String;
        final value = entry.value as YamlMap?;

        yield Variable.fromYaml(name, value);
      }
    }

    final nameConfigYaml = YamlValue.from(data.remove('name'));

    String? name, prefix, suffix;

    if (nameConfigYaml.isYaml()) {
      final nameConfig = nameConfigYaml.asYaml().value.data;

      name = nameConfig.remove('value') as String?;
      prefix = nameConfig.remove('prefix') as String?;
      suffix = nameConfig.remove('suffix') as String?;

      if (nameConfig.isNotEmpty == true) {
        throw ArgumentError(
          'Unrecognized keys in file config: ${nameConfig.keys}',
        );
      }
    } else if (nameConfigYaml.isString()) {
      name = nameConfigYaml.asString().value;
    } else if (nameConfigYaml.isNone() && yaml.value.containsKey('name')) {
      name = basenameWithoutExtension(path);
    }

    if (data.isNotEmpty) {
      throw ArgumentError('Unrecognized keys in file config: ${data.keys}');
    }

    return BrickFile._fromYaml(
      path,
      variables: variables(),
      prefix: prefix,
      suffix: suffix,
      name: name,
    );
  }

  final String path;
  final Iterable<Variable> variables;
  final String? prefix;
  final String? suffix;
  final String? name;

  String get fileName {
    if (name == null) {
      return basename(path);
    }
    final prefix = this.prefix ?? '';
    final suffix = this.suffix ?? '';

    final formattedName = '$prefix{{{$name}}}$suffix';
    final mustacheName = MustacheFormat.snakeCase.toMustache(formattedName);

    return '$mustacheName$extension';
  }

  String get extension => p.extension(path, 10);

  void writeTargetFile({
    required String targetDir,
    required File sourceFile,
    required Iterable<BrickPath> configuredDirs,
    required FileSystem fileSystem,
  }) {
    var path = this.path;
    path = path.replaceAll(basename(path), '');
    path = join(path, fileName);

    if (path.contains(separator)) {
      final originalPath = path;

      for (final configDir in configuredDirs) {
        path = configDir.apply(path, originalPath: originalPath);
      }
    }

    final file = fileSystem.file(join(targetDir, path));

    try {
      file.createSync(recursive: true);
    } catch (e) {
      print(e);
      return;
    }

    if (variables.isEmpty == true) {
      sourceFile.copySync(file.path);

      return;
    }

    var content = sourceFile.readAsStringSync();

    for (final variable in variables) {
      final pattern = RegExp('(.*)${variable.placeholder}' r'(\w*!?)(.*)');
      content = content.replaceAllMapped(pattern, (match) {
        final value = match.group(2);

        final loop = MustacheLoops.values.retrieve(value);
        if (loop != null) {
          return MustacheLoops.toMustache(variable.name, () => loop);
        }

        final format = MustacheFormat.values.retrieve('${value}Case');

        String result;
        if (format == null) {
          result = variable.formattedName;
        } else {
          result = variable.formatName(format);
        }

        final beforeMatch = match.group(1) ?? '';
        final afterMatch = match.group(3) ?? '';

        return '$beforeMatch$result$afterMatch';
      });
    }

    file.writeAsStringSync(content);
  }

  @override
  List<Object?> get props => [
        path,
        variables.toList(),
        prefix,
        suffix,
        name,
      ];
}
