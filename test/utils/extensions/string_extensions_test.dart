import 'package:test/test.dart';
import 'package:brick_oven/utils/extensions/string_extensions.dart';

void main() {
  group('#whitespacePattern', () {
    test('has correct value', () {
      expect(StringX.whitespacePattern, RegExp(r'^\S+$'));
    });

    test('matches', () {
      const matches = [
        '123',
        'abc',
        r'<>(){}[].-_+=!@#\$%^&*',
      ];

      for (final match in matches) {
        expect(StringX.whitespacePattern.hasMatch(match), isTrue);
      }
    });
  });

  test('#containsWhitespace matches', () {
    const matches = [
      '123 ',
      ' abc',
      r'<>(){}[].-_+=!@#\$%^&* ',
    ];

    for (final match in matches) {
      expect(match.containsWhitespace(), isTrue);
    }
  });

  test('#doesNotContainsWhitespace', () {
    const matches = [
      '1 3',
      'a\nc',
      'a\tc',
    ];

    for (final match in matches) {
      expect(match.doesNotContainWhitespace(), isTrue);
    }
  });
}
