class MustacheLoops {
  static const start = 'start';
  static const end = 'end';
  static const startInvert = 'nstart';

  static const values = [start, end, startInvert];

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
