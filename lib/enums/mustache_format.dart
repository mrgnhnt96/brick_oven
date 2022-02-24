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
}

/// the extensions for Mustache
extension MustacheFormatX on MustacheFormat {
  /// Wraps the [content] with mustache
  ///
  /// eg: {{#snakeCase}}This is the content{{/snakeCase}}
  String toMustache(
    String content, {
    bool invert = false,
  }) {
    final entry = invert ? '^' : '#';

    return '{{$entry$name}}$content{{/$name}}';
  }
}

/// The extensions for Lists
extension ListX<T> on List<T> {
  /// loops through looking for a matched [value], return null if not found
  T? retrieve(Object? value) {
    for (final e in this) {
      if (e is Enum) {
        if (e.name.toLowerCase() == '$value'.toLowerCase()) {
          return e;
        }
      } else if (e is String) {
        if (e.toLowerCase() == '$value'.toLowerCase()) {
          return e;
        }
      } else {
        if (e == value) {
          return e;
        }
      }
    }

    return null;
  }
}
