// ignore_for_file: parameter_assignments

/// the formats that Mustache supports
enum MustacheFormat {
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
  escape,

  /// start of an inverted inline section
  ifNot,

  /// start of an inline section
  if_,

  /// end of an inline section
  endIf,
}

/// the extensions for Mustache
extension MustacheFormatX on MustacheFormat {
  /// Wraps the [content] with mustache
  ///
  /// eg: {{#snakeCase}}This is the content{{/snakeCase}}
  String toMustache(String content) {
    assert(
      content.contains('{{{') && content.contains('}}}'),
      'Content must be wrapped with {{{}}}',
    );

    if (isEscape) {
      return content;
    }

    return '{{#$name}}$content{{/$name}}';
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

  /// whether the format is [MustacheFormat.escape]
  bool get isEscape => this == MustacheFormat.escape;

  /// whether the format is [MustacheFormat.if_]
  bool get isIf => this == MustacheFormat.if_;

  /// whether the format is [MustacheFormat.ifNot]
  bool get isIfNot => this == MustacheFormat.ifNot;

  /// whether the format is [MustacheFormat.endIf]
  bool get isEndIf => this == MustacheFormat.endIf;

  /// whether the value is [MustacheFormat.camelCase]
  bool get isCamelCase => this == MustacheFormat.camelCase;

  /// whether the value is [MustacheFormat.constantCase]
  bool get isConstantCase => this == MustacheFormat.constantCase;

  /// whether the value is [MustacheFormat.dotCase]
  bool get isDotCase => this == MustacheFormat.dotCase;

  /// whether the value is [MustacheFormat.headerCase]
  bool get isHeaderCase => this == MustacheFormat.headerCase;

  /// whether the value is [MustacheFormat.lowerCase]
  bool get isLowerCase => this == MustacheFormat.lowerCase;

  /// whether the value is [MustacheFormat.mustacheCase]
  bool get isMustacheCase => this == MustacheFormat.mustacheCase;

  /// whether the value is [MustacheFormat.pascalCase]
  bool get isPascalCase => this == MustacheFormat.pascalCase;

  /// whether the value is [MustacheFormat.paramCase]
  bool get isParamCase => this == MustacheFormat.paramCase;

  /// whether the value is [MustacheFormat.pathCase]
  bool get isPathCase => this == MustacheFormat.pathCase;

  /// whether the value is [MustacheFormat.sentenceCase]
  bool get isSentenceCase => this == MustacheFormat.sentenceCase;

  /// whether the value is [MustacheFormat.snakeCase]
  bool get isSnakeCase => this == MustacheFormat.snakeCase;

  /// whether the value is [MustacheFormat.titleCase]
  bool get isTitleCase => this == MustacheFormat.titleCase;

  /// whether the value is [MustacheFormat.upperCase]
  bool get isUpperCase => this == MustacheFormat.upperCase;
}

/// extension on [List<MustacheFormat>]
extension ListMustacheX on List<MustacheFormat> {
  /// loops through looking for a matched [value], return null if not found
  MustacheFormat? findFrom(String? value) {
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

  /// returns the suffix of the [value] by removing the [MustacheFormat]
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
