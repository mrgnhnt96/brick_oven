/// The loops from Mustache
class MustacheLoops {
  /// the start of the loop
  ///
  /// Format: {{#snakeCase}}
  static const start = 'start';

  /// the end of the loop
  ///
  /// Format: {{/snakeCase}}
  static const end = 'end';

  /// the intverted start of the loop
  ///
  /// Format: {{^snakeCase}}
  static const startInvert = 'nstart';

  /// all the loop values of [MustacheLoops]
  static const values = [start, end, startInvert];

  /// formats the [name] to be wrapped as mustache
  static String toMustache(String name, String Function() loop) {
    return loop().getloop(name);
  }
}

extension on String {
  String getloop(String key) {
    switch (this) {
      case MustacheLoops.start:
        return '{{#$key}}';
      case MustacheLoops.startInvert:
        return '{{^$key}}';
      case MustacheLoops.end:
        return '{{/$key}}';
      default:
        throw ArgumentError('Invalid loop type');
    }
  }
}
