import 'package:brick_oven/domain/take_2/name_config.dart';
import 'package:brick_oven/domain/take_2/utils/variables_mixin.dart';

abstract class Name extends NameConfig with VariablesMixin {
  Name(super.config) : super.self();

  String get originalName;

  /// returns the name of the file with formatting to mustache
  ///
  /// [trailing] gets appended to the end of the name _AFTER_
  /// wrapping the name with braces & formatting but _BEFORE_
  /// wrapping with the section tag
  ///
  /// [postStartBraces] & [preEndBraces] gets prepended to the name _BEFORE_
  /// wrapping the name with braces & formatting
  String format({
    String trailing = '',
    String postStartBraces = '',
    String preEndBraces = '',
  });
}
