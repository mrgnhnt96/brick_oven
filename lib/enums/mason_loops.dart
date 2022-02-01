class MasonLoops {
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
      case MasonLoops.start:
        return '{{#$key}}';
      case MasonLoops.startInvert:
        return '{{^$key}}';
      case MasonLoops.end:
        return '{{/$key}}';
      default:
        throw Exception('Invalid loop type');
    }
  }
}
