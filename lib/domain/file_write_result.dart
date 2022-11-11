import 'package:brick_oven/domain/brick_partial.dart';
import 'package:brick_oven/domain/variable.dart';

///
class FileWriteResult {
  ///
  const FileWriteResult({
    required this.usedPartials,
    required this.usedVariables,
  });

  ///
  final Set<Variable> usedVariables;

  ///
  final Set<BrickPartial> usedPartials;
}
