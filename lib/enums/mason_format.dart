// ignore_for_file: parameter_assignments

enum MasonFormat {
  camelCase,
  constantCase,
  dotCase,
  headerCase,
  lowerCase,
  pascalCase,
  paramCase,
  pathCase,
  sentenceCase,
  snakeCase,
  titleCase,
  upperCase,
}

extension MasonFormatX on MasonFormat {
  String toMustache(
    String content, {
    bool invert = false,
  }) {
    final entry = invert ? '^' : '#';

    return '{{$entry$name}}$content{{/$name}}';
  }
}

extension EnumListX<T> on List<T> {
  T? retrieve(String? value) {
    value = value?.toLowerCase();

    for (final e in this) {
      if (e is Enum) {
        if (e.name.toLowerCase() == value) {
          return e;
        }
      } else if (e is String) {
        if (e.toLowerCase() == value) {
          return e;
        }
      } else {
        if (e == value) {
          return e;
        }
      }
    }
  }
}
