import 'package:autoequal/autoequal.dart';
import 'package:brick_oven/domain/brick_dir.dart';
import 'package:brick_oven/domain/file_write_result.dart';
import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/partial.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/file_replacements.dart';
import 'package:equatable/equatable.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p show extension;
import 'package:path/path.dart' hide extension;

part 'brick_file.g.dart';

/// {@template brick_file}
/// Represents a file configured in a brick
/// {@endtemplate}
@autoequal
class BrickFile extends Equatable with FileReplacements {
  /// {macro brick_file}
  const BrickFile(this.path, {this.name})
      : variables = const [],
        includeIf = null,
        includeIfNot = null;

  /// configures the brick file will all available properties,
  /// should only be used in testing
  @visibleForTesting
  const BrickFile.config(
    this.path, {
    this.variables = const [],
    this.name,
    this.includeIf,
    this.includeIfNot,
  });

  /// parses the [yaml]
  factory BrickFile.fromYaml(
    YamlValue yaml, {
    required String path,
  }) {
    if (yaml.isError()) {
      throw FileException(
        file: path,
        reason: 'Invalid brick file: ${yaml.asError().value}',
      );
    }

    if (yaml.isNone()) {
      throw FileException(
        file: path,
        reason: 'Missing configuration, please remove this '
            'file or add configuration',
      );
    }

    if (!yaml.isYaml()) {
      throw FileException(
        file: path,
        reason: 'Invalid configuration -- Expected type `Map`',
      );
    }

    final data = Map<String, dynamic>.from(yaml.asYaml().value);

    final variablesData = YamlValue.from(data.remove('vars'));

    Iterable<Variable> variables() sync* {
      if (variablesData.isNone()) {
        return;
      }

      if (!variablesData.isYaml()) {
        throw FileException(
          file: path,
          reason: '`vars` must be of type `Map`',
        );
      }

      for (final entry in variablesData.asYaml().value.entries) {
        try {
          final name = entry.key as String;
          yield Variable.fromYaml(YamlValue.from(entry.value), name);
        } on ConfigException catch (e) {
          throw FileException(file: path, reason: e.message);
        }
      }
    }

    // name's value can be omitted
    final hasNameKey = data.containsKey('name');
    final nameYaml = YamlValue.from(data.remove('name'));

    Name? name;

    if (!nameYaml.isNone() || hasNameKey) {
      try {
        name = Name.fromYaml(nameYaml, basenameWithoutExtension(path));
      } on ConfigException catch (e) {
        throw FileException(file: path, reason: e.message);
      }
    }

    String? getValue(String key) {
      final yaml = YamlValue.from(data.remove(key));

      if (yaml.isNone()) {
        return null;
      }

      if (!yaml.isString()) {
        throw FileException(
          file: path,
          reason: 'Expected type `String` or `null` for `$key`',
        );
      }

      return yaml.asString().value;
    }

    final includeIf = getValue('include_if');
    final includeIfNot = getValue('include_if_not');

    if (includeIf != null && includeIfNot != null) {
      throw FileException(
        file: path,
        reason: 'Cannot use both `include_if` and `include_if_not`',
      );
    }

    if (data.isNotEmpty) {
      throw FileException(
        file: path,
        reason: 'Unknown keys: "${data.keys.join('", "')}"',
      );
    }

    return BrickFile.config(
      path,
      variables: variables().toList(),
      name: name,
      includeIf: includeIf,
      includeIfNot: includeIfNot,
    );
  }

  /// whether to include the file in the _mason_ build output
  /// based on the variable provided
  ///
  /// wraps the file in a `{{#if}}` block
  final String? includeIf;

  /// whether to include the file in the _mason_ build output
  /// based on the variable provided
  ///
  /// wraps the file in a `{{^if}}` block
  final String? includeIfNot;

  /// the name of the file
  ///
  /// if provided, [formatName] will format the name
  /// using mustache
  final Name? name;

  /// the path of the file
  final String path;

  /// All variables that the content contains and will be updated with
  final List<Variable> variables;

  @override
  List<Object?> get props => _$props;

  /// all of the extensions of the file
  ///
  /// eg: `.g.dart`
  String get extension => p.extension(path, 10);

  /// the name of file with extension
  ///
  /// If [name], then the name will be formatted with mustache,
  /// prepended with prefix, and appended with suffix
  String formatName() {
    String name;
    if (this.name != null) {
      name = '${this.name!.format()}$extension';
    } else {
      name = basename(path);
    }

    if (includeIf != null) {
      return '{{#$includeIf}}$name{{/$includeIf}}';
    }

    if (includeIfNot != null) {
      return '{{^$includeIfNot}}$name{{/$includeIfNot}}';
    }

    return name;
  }

  /// writes the file in the [targetDir], with the
  /// contents of the [sourceFile].
  ///
  /// If there are any [dirs], they will be applied
  /// to the [path]
  FileWriteResult writeTargetFile({
    required String targetDir,
    required File sourceFile,
    required List<BrickDir> dirs,
    required List<Variable> outOfFileVariables,
    required List<Partial> partials,
    required FileSystem fileSystem,
    required Logger logger,
  }) {
    final dirNamesUsed = <String>{};
    final fileNamesUsed = <String>{};

    var newPath = path;
    newPath = newPath.replaceAll(basename(newPath), '');
    newPath = join(newPath, formatName());

    if (name != null) {
      fileNamesUsed.add(name!.value);
    }

    if (includeIf != null) {
      fileNamesUsed.add(includeIf!);
    }

    if (includeIfNot != null) {
      fileNamesUsed.add(includeIfNot!);
    }

    // check for any slashes not preceeded by {
    final slashPattern = RegExp(r'(?<!{+)\' '$separator');

    if (slashPattern.hasMatch(newPath)) {
      final originalPath = newPath;

      for (final configDir in dirs) {
        final comparePath = newPath;
        newPath = configDir.apply(newPath, originalPath: originalPath);

        if (newPath != comparePath) {
          final name = configDir.name?.value;
          if (name != null) {
            dirNamesUsed.add(name);
          }
        }
      }
    }

    final file = fileSystem.file(join(targetDir, newPath))
      ..createSync(recursive: true);

    try {
      final writeResult = writeFile(
        targetFile: file,
        sourceFile: sourceFile,
        variables: variables,
        outOfFileVariables: outOfFileVariables,
        partials: partials,
        fileSystem: fileSystem,
        logger: logger,
      );

      return FileWriteResult(
        usedPartials: writeResult.usedPartials,
        usedVariables: {
          ...writeResult.usedVariables,
          ...fileNamesUsed,
          ...dirNamesUsed,
        },
      );
    } on ConfigException catch (e) {
      throw FileException(
        file: sourceFile.path,
        reason: e.message,
      );
    }
  }
}
