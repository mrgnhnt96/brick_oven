import 'package:brick_oven/domain/implementations/variable_impl.dart';
import 'package:brick_oven/domain/interfaces/variable.dart';

/// Constants used throughout the package
class Constants {
  const Constants._();

  /// The name of the package
  static const String packageName = 'brick_oven';

  /// the value to be used for when accessing the current value of an array
  static const String kIndexValue = '_INDEX_VALUE_';

  /// the default number of braces to wrap a variable with
  static const int kDefaultBraces = 3;

  /// variables used not provided by the user
  static Set<Variable> get defaultVariables => {
        const VariableImpl(name: '.', placeholder: kIndexValue),
      };

  /// variables to ignore configuring the target file
  static List<String> get variablesToIgnore => [kIndexValue, '.'];

  static List<String> get excludedDirs => [
        '__brick__',
        'bricks',
        '.git',
        '.dart_tool',
      ];
}
