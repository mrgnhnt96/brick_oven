import 'package:brick_oven/enums/mustache_sections.dart';
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

    const loopSetUp = '---set-up-loop---';

    for (final variable in variables) {
      final loopPattern = RegExp('.*$loopSetUp' r'({{.[\w-+$\.]+}}).*');
      final variablePattern =
          RegExp(r'([\w-{#^/]*)' '${variable.placeholder}' r'([\w}]*)');

      String checkForLoops(String content) {
        final setUpLoops = content.replaceAllMapped(variablePattern, (match) {
          final possibleLoop = match.group(1);
          final loop = MustacheLoops.values.from(possibleLoop);

          // if loop is found, then replace the content
          if (loop == null) {
            return match.group(0)!;
          }

          final formattedLoop = loop.format(variable.name);

          return '$loopSetUp$formattedLoop';
        });

        // remove the loop setup and all pre/post content
        final looped = setUpLoops.replaceAllMapped(loopPattern, (match) {
          return match.group(1)!;
        });

        // remove all extra linebreaks before & after the loop
        final clean = looped.replaceAllMapped(
          RegExp(r'(\n*)({{[#^/][\w-]+}})$(\n*)', multiLine: true),
          (match) {
            var before = '', after = '';

            final beforeMatch = match.group(1);
            if (beforeMatch != null && beforeMatch.isNotEmpty) {
              before = '\n';
            }

            final afterMatch = match.group(3);
            if (afterMatch != null && afterMatch.isNotEmpty) {
              after = '\n';
            }

            return '$before${match.group(2)!}$after';
          },
        );

        return clean;
      }

      String checkForVariables(String content) {
        return content.replaceAllMapped(variablePattern, (match) {
          final possibleSection = match.group(1);
          MustacheSections? section;
          String result, suffix = '', prefix = '';

          // check for section or loop
          if (possibleSection != null && possibleSection.isNotEmpty) {
            section = MustacheSections.values.from(possibleSection);

            if (section == null) {
              prefix = possibleSection;
            } else {
              prefix = prefix.replaceAll(section.matcher, '');
            }
          }

          final possibleFormat = match.group(2);

          final format = MustacheFormat.values.getMustacheValue(possibleFormat);

          if (format == null) {
            if (possibleFormat != null && possibleFormat.isNotEmpty) {
              suffix = possibleFormat;
            }

            if (section == null) {
              result = '{{${variable.name}}}';
            } else {
              result = section.format(variable.name);
            }
          } else {
            // format the variable
            suffix = MustacheFormat.values.getSuffix(possibleFormat) ?? '';
            result = variable.formatName(format);
          }

          if (prefix.startsWith(RegExp('{{[#^/]')) || suffix.endsWith('}}')) {
            return match.group(0)!;
          }

          return '$prefix$result$suffix';
        });
      }

      // formats the content
      content = checkForLoops(content);
      content = checkForVariables(content);
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
