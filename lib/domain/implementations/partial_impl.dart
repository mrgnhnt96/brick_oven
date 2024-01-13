import 'package:brick_oven/domain/file_write_result.dart';
import 'package:brick_oven/domain/interfaces/partial.dart';
import 'package:brick_oven/domain/interfaces/variable.dart';
import 'package:brick_oven/domain/take_2/utils/file_replacements.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:path/path.dart' as p;

/// {@macro partial}
class PartialImpl extends Partial with FileReplacements {
  /// {@macro partial}
  PartialImpl(
    super.config, {
    required this.sourceFile,
    required this.outputDir,
  });

  @override
  final String sourceFile;

  @override
  final String outputDir;

  @override
  FileWriteResult write({
    required Iterable<Partial> partials,
    required Set<Variable> outOfFileVariables,
  }) {
    try {
      return writeFile(
        targetPath: p.join(outputDir, toPartialFile()),
        sourcePath: sourceFile,
        variables: variables,
        outOfFileVariables: outOfFileVariables,
        partials: partials,
      );
    } catch (e) {
      if (e is ConfigException) {
        throw PartialException(
          partial: sourceFile,
          reason: e.message,
        );
      }

      throw PartialException(
        partial: sourceFile,
        reason: e.toString(),
      );
    }
  }

  @override
  String get name => p.basenameWithoutExtension(sourceFile);

  @override
  String get fileName => p.basename(sourceFile);
}
