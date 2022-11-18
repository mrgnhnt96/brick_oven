import 'package:test/test.dart';

import 'package:brick_oven/enums/mustache_section.dart';

void main() {
  group('$MustacheSection', () {
    test('#isStart', () {
      expect(MustacheSection.if_.isStart, isTrue);
      expect(MustacheSection.endIf.isStart, isFalse);
      expect(MustacheSection.ifNot.isStart, isFalse);
    });

    test('#isEnd', () {
      expect(MustacheSection.if_.isEnd, isFalse);
      expect(MustacheSection.endIf.isEnd, isTrue);
      expect(MustacheSection.ifNot.isEnd, isFalse);
    });

    test('#isInvert', () {
      expect(MustacheSection.if_.isInvert, isFalse);
      expect(MustacheSection.endIf.isInvert, isFalse);
      expect(MustacheSection.ifNot.isInvert, isTrue);
    });

    group('#symbol', () {
      test('returns the symbol of the start section', () {
        expect(MustacheSection.if_.symbol, '#');
      });

      test('returns the symbol of the end section', () {
        expect(MustacheSection.endIf.symbol, '/');
      });

      test('returns the symbol of the invert section', () {
        expect(MustacheSection.ifNot.symbol, '^');
      });
    });

    group('#format', () {
      const defaultValue = 'hello';

      test('returns the format of the start section', () {
        expect(
          MustacheSection.if_.format(defaultValue),
          '{{#$defaultValue}}',
        );
      });

      test('returns the format of the end section', () {
        expect(
          MustacheSection.endIf.format(defaultValue),
          '{{/$defaultValue}}',
        );
      });

      test('returns the format of the invert section', () {
        expect(
          MustacheSection.ifNot.format(defaultValue),
          '{{^$defaultValue}}',
        );
      });
    });
  });

  group('MustacheSectionList', () {
    const suffix = 'ASDF';

    const sectionsWithoutSuffixes = {
      MustacheSection.if_: [
        'if',
      ],
      MustacheSection.ifNot: [
        'ifNot',
        'ifnot',
      ],
      MustacheSection.endIf: [
        'endIf',
        'endif',
      ],
    };

    const sectionsWithSuffixes = {
      MustacheSection.if_: [
        'if$suffix',
      ],
      MustacheSection.ifNot: [
        'ifNot$suffix',
        'ifnot$suffix',
      ],
      MustacheSection.endIf: [
        'endIf$suffix',
        'endif$suffix',
      ],
    };

    test('MustacheSection.values', () {
      for (final value in MustacheSection.values) {
        expect(sectionsWithSuffixes, contains(value));
        expect(sectionsWithoutSuffixes, contains(value));
      }
    });

    group('#findFrom', () {
      test('returns the $MustacheSection from strings', () {
        final keys = sectionsWithoutSuffixes.keys;

        for (final key in keys) {
          for (final value in sectionsWithoutSuffixes[key]!) {
            final result = MustacheSection.values.findFrom(value);
            expect(result, key);
          }
        }
      });

      test('returns appropriate value when provided with suffixes', () {
        final keys = sectionsWithSuffixes.keys;

        for (final key in keys) {
          for (final value in sectionsWithSuffixes[key]!) {
            final result = MustacheSection.values.findFrom(value);
            expect(result, key);
          }
        }
      });

      test('returns null when value is not found', () {
        expect(MustacheSection.values.findFrom('nothing'), isNull);
        expect(MustacheSection.values.findFrom(null), isNull);
      });
    });
  });
}
