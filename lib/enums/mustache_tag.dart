// ignore_for_file: parameter_assignments

import 'package:meta/meta.dart';

import 'package:brick_oven/utils/constants.dart';

/// the formats that Mustache supports
enum MustacheTag {
  /// camelCase
  camelCase,

  /// CONSTANT_CASE
  constantCase,

  /// dot.case
  dotCase,

  /// HeaderCase
  headerCase,

  /// lowercase
  lowerCase,

  /// {{ mustache }}
  mustacheCase,

  /// Pascal Case
  pascalCase,

  /// paramCase
  paramCase,

  /// path_case
  pathCase,

  /// Sentence Case
  sentenceCase,

  /// snake_case
  snakeCase,

  /// Title Case
  titleCase,

  /// UPPERCASE
  upperCase,

  /// no format, start of an inverted inline section
  ifNot,

  /// no format, start of an inline section
  if_,

  /// no format, end of an inline section
  endIf,
}

/// the extensions for Mustache
extension MustacheTagX on MustacheTag {
  /// the pattern to match if content is wrapped with brackets
  @visibleForTesting
  static RegExp get wrappedPattern => RegExp(r'\S*\{{2,3}\S+\}{2,3}\S*');

  /// Wraps the [content] with mustache
  ///
  /// eg: {{#snakeCase}}This is the content{{/snakeCase}}
  String wrap(
    String content, {
    int? braceCount,
    String? startDeliminator,
    String? endDeliminator,
  }) {
    assert(
      braceCount == null || braceCount >= 2 && braceCount <= 3,
      'braceCount must be 2 or 3',
    );

    assert(
      startDeliminator == null || startDeliminator.length == 1,
      'startDeliminator must be 1 character',
    );

    assert(
      endDeliminator == null || endDeliminator.length == 1,
      'endDeliminator must be 1 character',
    );

    assert(
      (startDeliminator == null) == (endDeliminator == null),
      'startDeliminator and endDeliminator must be null or not null',
    );

    if (startDeliminator != null && endDeliminator != null) {
      assert(
        startDeliminator != endDeliminator,
        'startDeliminator and endDeliminator must be different',
      );
    }

    final startBraces = (startDeliminator ?? '{') * 2;
    final endBraces = (endDeliminator ?? '}') * 2;

    if (isFormat) {
      final isWrapped = wrappedPattern.hasMatch(content);

      var wrappedContent = content;

      if (!isWrapped) {
        braceCount ??= kDefaultBraces;

        final startBraces = (startDeliminator ?? '{') * braceCount;
        final endBraces = (endDeliminator ?? '}') * braceCount;
        wrappedContent = '$startBraces$content$endBraces';
      }

      return '$startBraces#$name$endBraces$wrappedContent$startBraces/$name$endBraces';
    }

    assert(
      !wrappedPattern.hasMatch(content),
      'Content must not be wrapped with {{{}}} when not formatting content',
    );

    if (isIf) {
      return '$startBraces#$content$endBraces';
    }

    if (isIfNot) {
      return '$startBraces^$content$endBraces';
    }

    if (isEndIf) {
      return '$startBraces/$content$endBraces';
    }

    return content;
  }

  /// whether the value is a format type
  bool get isFormat {
    if (isCamelCase) return true;
    if (isConstantCase) return true;
    if (isDotCase) return true;
    if (isHeaderCase) return true;
    if (isLowerCase) return true;
    if (isMustacheCase) return true;
    if (isPascalCase) return true;
    if (isParamCase) return true;
    if (isPathCase) return true;
    if (isSentenceCase) return true;
    if (isSnakeCase) return true;
    if (isTitleCase) return true;
    if (isUpperCase) return true;

    return false;
  }

  /// whether the format is [MustacheTag.if_]
  bool get isIf => this == MustacheTag.if_;

  /// whether the format is [MustacheTag.ifNot]
  bool get isIfNot => this == MustacheTag.ifNot;

  /// whether the format is [MustacheTag.endIf]
  bool get isEndIf => this == MustacheTag.endIf;

  /// whether the value is [MustacheTag.camelCase]
  bool get isCamelCase => this == MustacheTag.camelCase;

  /// whether the value is [MustacheTag.constantCase]
  bool get isConstantCase => this == MustacheTag.constantCase;

  /// whether the value is [MustacheTag.dotCase]
  bool get isDotCase => this == MustacheTag.dotCase;

  /// whether the value is [MustacheTag.headerCase]
  bool get isHeaderCase => this == MustacheTag.headerCase;

  /// whether the value is [MustacheTag.lowerCase]
  bool get isLowerCase => this == MustacheTag.lowerCase;

  /// whether the value is [MustacheTag.mustacheCase]
  bool get isMustacheCase => this == MustacheTag.mustacheCase;

  /// whether the value is [MustacheTag.pascalCase]
  bool get isPascalCase => this == MustacheTag.pascalCase;

  /// whether the value is [MustacheTag.paramCase]
  bool get isParamCase => this == MustacheTag.paramCase;

  /// whether the value is [MustacheTag.pathCase]
  bool get isPathCase => this == MustacheTag.pathCase;

  /// whether the value is [MustacheTag.sentenceCase]
  bool get isSentenceCase => this == MustacheTag.sentenceCase;

  /// whether the value is [MustacheTag.snakeCase]
  bool get isSnakeCase => this == MustacheTag.snakeCase;

  /// whether the value is [MustacheTag.titleCase]
  bool get isTitleCase => this == MustacheTag.titleCase;

  /// whether the value is [MustacheTag.upperCase]
  bool get isUpperCase => this == MustacheTag.upperCase;
}

/// extension on [List<MustacheFormat>]
extension ListMustacheX on List<MustacheTag> {
  /// loops through looking for a matched [value], return null if not found
  MustacheTag? findFrom(String? value, {bool onlyFormat = false}) {
    if (value == null) {
      return null;
    }

    final valueLower = value.toLowerCase();

    for (final e in this) {
      final name = e.name.toLowerCase().replaceAll('_', '');
      if (!onlyFormat) {
        if (valueLower.startsWith(name)) {
          return e;
        }
      }

      if (!e.isFormat) {
        continue;
      }

      if (valueLower.startsWith(e.name.replaceAll('Case', ''))) {
        return e;
      }
    }

    return null;
  }

  /// returns the suffix of the [value] by removing the [MustacheTag]
  String? suffixFrom(String? value) {
    if (value == null) {
      return null;
    }

    final mustacheFormat = findFrom(value);

    if (mustacheFormat == null) {
      return null;
    }

    final mustacheName = mustacheFormat.name.toLowerCase().replaceAll('_', '');
    final valueLower = value.toLowerCase();

    if (valueLower.startsWith(mustacheName)) {
      return value.substring(mustacheName.length);
    }

    final shortMustacheName = mustacheName.replaceAll('case', '');

    if (valueLower.startsWith(shortMustacheName)) {
      return value.substring(shortMustacheName.length);
    }

    return null;
  }
}
