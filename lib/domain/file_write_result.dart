import 'package:brick_oven/domain/brick_partial.dart';
import 'package:brick_oven/domain/variable.dart';

///
class FileWriteResult {
  ///
  const FileWriteResult({
    required this.unusedPartials,
    required this.unusedVariables,
  });

  ///
  final Set<Variable> unusedVariables;

  ///
  final Set<BrickPartial> unusedPartials;
}
