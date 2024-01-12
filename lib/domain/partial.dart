import 'package:autoequal/autoequal.dart';
import 'package:brick_oven/domain/file_write_result.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/di.dart';
import 'package:brick_oven/utils/extensions/yaml_map_extensions.dart';
import 'package:brick_oven/utils/file_replacements.dart';
import 'package:equatable/equatable.dart';
import 'package:file/file.dart';
import 'package:path/path.dart';

part 'partial.g.dart';

/// {@template partial}
/// A partial is a template that can be re-used within files
/// {@endtemplate}
@autoequal
class Partial extends Equatable with FileReplacements {
  /// {@macro partial}
  const Partial({
    required this.path,
    this.variables = const [],
  });

  /// {@macro partial}
  factory Partial.fromYaml(YamlValue yaml, String path) {
    if (yaml.isError()) {
      throw PartialException(
        partial: path,
        reason: 'Invalid configuration',
      );
    }

    if (yaml.isNone()) {
      return Partial(path: path);
    }

    if (!yaml.isYaml()) {
      throw PartialException(
        partial: path,
        reason: 'Expected type `Map` or `null`',
      );
    }

    final data = yaml.asYaml().value;

    final varsYaml = YamlValue.from(data['vars']);

    if (varsYaml.isError()) {
      throw PartialException(
        partial: path,
        reason: 'Invalid variables configuration',
      );
    }

    if (varsYaml.isNone()) {
      return Partial(path: path);
    }

    if (!varsYaml.isYaml()) {
      throw PartialException(
        partial: path,
        reason: 'Expected type `Map` or `null`',
      );
    }

    final vars = varsYaml.asYaml().value.data;

    final variables = <Variable>[];

    for (final entry in vars.entries) {
      try {
        final variable = Variable.fromYaml(
          YamlValue.from(entry.value),
          entry.key,
        );
        variables.add(variable);
      } on ConfigException catch (e) {
        throw PartialException(
          partial: path,
          reason: e.message,
        );
      } catch (e) {
        throw PartialException(
          partial: path,
          reason: e.toString(),
        );
      }
    }

    return Partial(
      path: path,
      variables: variables,
    );
  }

  /// the path to the partial file
  final String path;

  /// the variables within the partial
  final List<Variable> variables;

  /// returns the name of the partial
  String get name => basenameWithoutExtension(path);

  /// returns the file name and extension of the partial
  String get fileName => basename(path);

  /// returns the [fileName] wrapped with `{{>` and `}}`
  String toPartialFile() {
    return '{{~ $fileName }}';
  }

  /// returns the [fileName] wrapped with `{{~` and `}}`
  String toPartialInput() {
    return '{{> $fileName }}';
  }

  /// writes the partial file replacing variables and partials with
  /// their respective values
  FileWriteResult writeTargetFile({
    required String targetDir,
    required File sourceFile,
    required List<Partial> partials,
    required List<Variable> outOfFileVariables,
  }) {
    final file = di<FileSystem>().file(join(targetDir, toPartialFile()))
      ..createSync(recursive: true);

    try {
      return writeFile(
        targetFile: file,
        sourceFile: sourceFile,
        variables: variables,
        outOfFileVariables: outOfFileVariables,
        partials: partials,
      );
    } catch (e) {
      if (e is ConfigException) {
        throw PartialException(
          partial: sourceFile.path,
          reason: e.message,
        );
      }

      throw PartialException(
        partial: sourceFile.path,
        reason: e.toString(),
      );
    }
  }

  @override
  List<Object?> get props => _$props;
}
