import 'package:autoequal/autoequal.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:brick_oven/utils/file_replacements.dart';
import 'package:brick_oven/domain/file_write_result.dart';
import 'package:equatable/equatable.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';

part 'brick_partial.g.dart';

/// {@template brick_partial}
/// A partial is a template that can be re-used within files
/// {@endtemplate}
@autoequal
class BrickPartial extends Equatable with FileReplacements {
  /// {@macro brick_partial}
  const BrickPartial({
    required this.path,
    this.variables = const [],
  });

  /// {@macro brick_partial}
  factory BrickPartial.fromYaml(YamlValue yaml, String path) {
    if (yaml.isError()) {
      throw PartialException(
        partial: path,
        reason: 'Invalid configuration',
      );
    }

    if (yaml.isNone()) {
      return BrickPartial(path: path);
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
      return BrickPartial(path: path);
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
      }
    }

    return BrickPartial(
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

  /// returns the file extension of the partial
  String get fileExt => extension(path);

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

  ///
  FileWriteResult writeTargetFile({
    required String targetDir,
    required File sourceFile,
    required List<BrickPartial> partials,
    required FileSystem? fileSystem,
    required Logger logger,
  }) {
    fileSystem ??= const LocalFileSystem();

    final file = fileSystem.file(join(targetDir, toPartialFile()))
      ..createSync(recursive: true);

    return writeFile(
      targetFile: file,
      sourceFile: sourceFile,
      variables: variables,
      partials: partials,
      fileSystem: fileSystem,
      logger: logger,
    );
  }

  @override
  List<Object?> get props => _$props;
}
