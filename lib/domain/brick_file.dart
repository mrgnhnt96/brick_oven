import 'package:equatable/equatable.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p show extension;
import 'package:path/path.dart' hide extension;
import 'package:yaml/yaml.dart';

import 'package:brick_oven/domain/brick_path.dart';
import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_format.dart';
import 'package:brick_oven/enums/mustache_loops.dart';
import 'package:brick_oven/utils/extensions.dart';

/// {@template brick_file}
/// Represents the file from the `brick_oven.yaml` file
/// {@endtemplate}
class BrickFile extends Equatable {
  /// {macro brick_file}
  const BrickFile(this.path, {this.name}) : variables = const [];

  const BrickFile._fromYaml(
    this.path, {
    required this.variables,
    required this.name,
  });

  /// configures the brick file will all available properties,
  /// should only be used in testing
  @visibleForTesting
  const BrickFile.config(
    this.path, {
    this.variables = const [],
    this.name,
  });

  /// parses the [yaml]
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
        yield Variable.from(name, entry.value);
      }
    }

    final nameYaml = YamlValue.from(data.remove('name'));

    Name? name;

    // name's value can be omitted
    if (!nameYaml.isNone() || yaml.value.containsKey('name')) {
      name = Name.fromYamlValue(nameYaml, basenameWithoutExtension(path));
    }

    if (data.isNotEmpty) {
      throw ArgumentError('Unrecognized keys in file config: ${data.keys}');
    }

    return BrickFile._fromYaml(
      path,
      variables: variables(),
      name: name,
    );
  }

  /// the path of the file
  final String path;

  /// All variables that the content contains and will be updated with
  final Iterable<Variable> variables;

  /// the name of the file
  ///
  /// if provided, [fileName] will format the name
  /// using mustache
  final Name? name;

  /// if the name of the file has been configured
  bool get hasConfiguredName => name != null;

  /// gets the name of the file without formatting to mustache
  String get simpleName {
    if (!hasConfiguredName) {
      return basename(path);
    }

    return '${name!.simple}$extension';
  }

  /// the name of file with extension
  ///
  /// If [hasConfiguredName], then the name will be formatted with mustache,
  /// prepended with prefix, and appended with suffix
  String get fileName {
    if (!hasConfiguredName) {
      return basename(path);
    }

    return '${name!.format(MustacheFormat.snakeCase)}$extension';
  }

  /// all of the extensions of the file
  ///
  /// eg: `.g.dart`
  String get extension => p.extension(path, 10);

  /// writes the file in the [targetDir], with the
  /// contents of the [sourceFile].
  ///
  /// If there are any [configuredDirs], they will be applied
  /// to the [path]
  void writeTargetFile({
    required String targetDir,
    required File sourceFile,
    required Iterable<BrickPath> configuredDirs,
    required FileSystem? fileSystem,
  }) {
    fileSystem ??= const LocalFileSystem();
    var path = this.path;
    path = path.replaceAll(basename(path), '');
    path = join(path, fileName);

    if (path.contains(separator)) {
      final originalPath = path;

      for (final configDir in configuredDirs) {
        path = configDir.apply(path, originalPath: originalPath);
      }
    }

    final file = fileSystem.file(join(targetDir, path))
      ..createSync(recursive: true);

    if (variables.isEmpty == true) {
      sourceFile.copySync(file.path);

      return;
    }

    var content = sourceFile.readAsStringSync();

    for (final variable in variables) {
      final pattern = RegExp('(.*)${variable.placeholder}' r'(\w*)(.*)');
      content = content.replaceAllMapped(pattern, (match) {
        final value = match.group(2);

        final loop = MustacheLoops.values.retrieve(value);
        if (loop != null) {
          return MustacheLoops.toMustache(variable.name, () => loop);
        }

        final format = MustacheFormat.values.retrieve(value) ??
            MustacheFormat.values.retrieve('${value}Case');

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
        name,
      ];
}
