// ignore_for_file: parameter_assignments

import 'package:meta/meta.dart';

/// the formats that Mustache supports
enum MustacheTags {
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

  /// no format, but wrapped with `{{{}}}`
  escaped,

  /// no format, but wrapped with `{{{}}}`
  unescaped,

  /// start of an inverted inline section
  ifNot,

  /// start of an inline section
  if_,

  /// end of an inline section
  endIf,
}

/// the extensions for Mustache
extension MustacheFormatX on MustacheTags {
  /// the pattern to match if content is wrapped with brackets
  @visibleForTesting
  static RegExp get wrappedPattern => RegExp(r'\S*\{{2,3}\S+\}{2,3}\S*');

  /// Wraps the [content] with mustache
  ///
  /// eg: {{#snakeCase}}This is the content{{/snakeCase}}
  String wrap(String content) {
    if (isFormat) {
      final isWrapped = wrappedPattern.hasMatch(content);

      var wrappedContent = content;

      if (!isWrapped) {
        wrappedContent = '{{{$content}}}';
      }

      return '{{#$name}}$wrappedContent{{/$name}}';
    }

    assert(
      !wrappedPattern.hasMatch(content),
      'Content must not be wrapped with {{{}}} when not formatting content',
    );

    if (isEscaped) {
      return '{{{$content}}}';
    }

    if (isUnescaped) {
      return '{{$content}}';
    }

    if (isIf) {
      return '{{#$content}}';
    }

    if (isIfNot) {
      return '{{^$content}}';
    }

    if (isEndIf) {
      return '{{/$content}}';
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

  /// whether the format is [MustacheTags.escaped]
  bool get isEscaped => this == MustacheTags.escaped;

  /// whether the format is [MustacheTags.unescaped]
  bool get isUnescaped => this == MustacheTags.unescaped;

  /// whether the format is [MustacheTags.if_]
  bool get isIf => this == MustacheTags.if_;

  /// whether the format is [MustacheTags.ifNot]
  bool get isIfNot => this == MustacheTags.ifNot;

  /// whether the format is [MustacheTags.endIf]
  bool get isEndIf => this == MustacheTags.endIf;

  /// whether the value is [MustacheTags.camelCase]
  bool get isCamelCase => this == MustacheTags.camelCase;

  /// whether the value is [MustacheTags.constantCase]
  bool get isConstantCase => this == MustacheTags.constantCase;

  /// whether the value is [MustacheTags.dotCase]
  bool get isDotCase => this == MustacheTags.dotCase;

  /// whether the value is [MustacheTags.headerCase]
  bool get isHeaderCase => this == MustacheTags.headerCase;

  /// whether the value is [MustacheTags.lowerCase]
  bool get isLowerCase => this == MustacheTags.lowerCase;

  /// whether the value is [MustacheTags.mustacheCase]
  bool get isMustacheCase => this == MustacheTags.mustacheCase;

  /// whether the value is [MustacheTags.pascalCase]
  bool get isPascalCase => this == MustacheTags.pascalCase;

  /// whether the value is [MustacheTags.paramCase]
  bool get isParamCase => this == MustacheTags.paramCase;

  /// whether the value is [MustacheTags.pathCase]
  bool get isPathCase => this == MustacheTags.pathCase;

  /// whether the value is [MustacheTags.sentenceCase]
  bool get isSentenceCase => this == MustacheTags.sentenceCase;

  /// whether the value is [MustacheTags.snakeCase]
  bool get isSnakeCase => this == MustacheTags.snakeCase;

  /// whether the value is [MustacheTags.titleCase]
  bool get isTitleCase => this == MustacheTags.titleCase;

  /// whether the value is [MustacheTags.upperCase]
  bool get isUpperCase => this == MustacheTags.upperCase;
}

/// extension on [List<MustacheFormat>]
extension ListMustacheX on List<MustacheTags> {
  /// loops through looking for a matched [value], return null if not found
  MustacheTags? findFrom(String? value) {
    if (value == null) {
      return null;
    }

    final valueLower = value.toLowerCase();

    for (final e in this) {
      final name = e.name.toLowerCase().replaceAll('_', '');

      if (valueLower.startsWith(name)) {
        return e;
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

  /// returns the suffix of the [value] by removing the [MustacheTags]
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
