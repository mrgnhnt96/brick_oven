import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';

/// a mixin for [includeIf] and [includeIfNot]
mixin IncludeMixin {
  /// whether to include the file in the _mason_ build output
  /// based on the variable provided
  ///
  /// wraps the file in a `{{^if}}` block
  String? get includeIf;

  /// whether to include the file in the _mason_ build output
  /// based on the variable provided
  ///
  /// wraps the file in a `{{^if}}` block
  String? get includeIfNot;

  /// retrieves [includeIf] or [includeIfNot] from [yaml]
  static String? getInclude(YamlValue yaml, String type) {
    if (yaml.isNone()) {
      return null;
    }

    if (!yaml.isString()) {
      throw BrickConfigException(
        reason: 'Expected type `String` or `null` for `$type`',
      );
    }

    return yaml.asString().value;
  }
}
