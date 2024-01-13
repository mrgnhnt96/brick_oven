import 'package:brick_oven/domain/implementations/variable_impl.dart';
import 'package:brick_oven/domain/interfaces/variable.dart';
import 'package:brick_oven/domain/take_2/utils/vars_mixin.dart';

mixin VariablesMixin on VarsMixin {
  Iterable<Variable> get variables sync* {
    for (final (String placeholder, String variable) in varsMap) {
      if (placeholder == '.') continue;

      yield VariableImpl(name: variable, placeholder: placeholder);
    }
  }
}
