import 'package:brick_oven/domain/config/partial_config.dart';
import 'package:brick_oven/domain/file_write_result.dart';
import 'package:brick_oven/domain/interfaces/variable.dart';
import 'package:brick_oven/utils/variables_mixin.dart';

/// {@template partial}
/// The base class for a partial file
/// {@endtemplate}
abstract class Partial extends PartialConfig with VariablesMixin {
  /// {@macro partial}
  Partial(
    super.config,
  ) : super.self();

  /// the name of the partial
  String get name;

  /// The path to where the partial will be written
  String get outputDir;

  /// The path to where the partial is located
  String get sourceFile;

  /// returns the file name and extension of the partial
  String get fileName;

  /// returns the [fileName] wrapped with `{{>` and `}}`
  String toPartialFile() {
    return '{{~ $fileName }}';
  }

  /// returns the [fileName] wrapped with `{{~` and `}}`
  String toPartialInput() {
    return '{{> $fileName }}';
  }

  /// writes the partial to the target file
  FileWriteResult write({
    required Iterable<Partial> partials,
    required Set<Variable> outOfFileVariables,
  });
}
