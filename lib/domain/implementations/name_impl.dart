import 'package:path/path.dart';

import 'package:brick_oven/domain/interfaces/name.dart';
import 'package:brick_oven/enums/mustache_tag.dart';
import 'package:brick_oven/utils/constants.dart';

/// {@macro name}
class NameImpl extends Name {
  /// {@macro name}
  NameImpl(
    super.config, {
    required String originalName,
  }) : originalName = basenameWithoutExtension(originalName);

  @override
  final String originalName;

  @override
  String format({
    String trailing = '',
    String postStartBraces = '',
    String preEndBraces = '',
  }) {
    var result = renameWith ?? originalName;

    if (result == Constants.kIndexValue) {
      result = '.';
    }

    result = '$postStartBraces$result$preEndBraces';

    if (tag != null) {
      result = tag!.wrap(result, braceCount: braces);
    } else {
      final startBraces = '{' * braces;
      final endBraces = '}' * braces;
      result = '$startBraces$result$endBraces';
    }

    result = '$prefix$result$suffix$trailing';

    final section = this.section?.object?.name ?? this.section?.string;
    final isInverted = this.section?.object?.isInverted ?? false;

    if (section != null) {
      String start;
      String end;

      if (isInverted) {
        start = MustacheTag.ifNot.wrap(section);
      } else {
        start = MustacheTag.if_.wrap(section);
      }

      end = MustacheTag.endIf.wrap(section);

      result = '$start$result$end';
    }

    return result;
  }
}
