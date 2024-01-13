import 'package:brick_oven/domain/implementations/variable_impl.dart';
import 'package:brick_oven/domain/interfaces/variable.dart';
import 'package:brick_oven/utils/vars_mixin.dart';

mixin VariablesMixin on VarsMixin {
  /// retrieves all variables from the [VarsMixin.varsMap]
  Iterable<Variable> get variables sync* {
    for (final (String placeholder, String variable) in varsMap) {
      if (placeholder == '.') continue;

      yield VariableImpl(name: variable, placeholder: placeholder);
    }
  }
}
