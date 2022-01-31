class MasonLoops {
  static const start = 'start';
  static const end = 'end';
  static const startInvert = 'start!';

  static const values = [start, end, startInvert];

  static String toMustache(String name, String Function() loop) {
    return loop().getloop(name);
  }
}

extension on String {
  String getloop(String key) {
    switch (this) {
      case 'start':
        return '{{#$key}}';
      case 'end':
        return '{{/$key}}';
      case 'start!':
        return '{{^$key}}';
      default:
        throw Exception('Invalid loop type');
    }
  }
}
