import 'package:test/test.dart';

import 'package:brick_oven/enums/mustache_section.dart';

void main() {
  group('$MustacheSection', () {
    test('#isStart', () {
      expect(MustacheSection.section.isStart, isTrue);
      expect(MustacheSection.endSection.isStart, isFalse);
      expect(MustacheSection.invertedSection.isStart, isFalse);
    });

    test('#isEnd', () {
      expect(MustacheSection.section.isEnd, isFalse);
      expect(MustacheSection.endSection.isEnd, isTrue);
      expect(MustacheSection.invertedSection.isEnd, isFalse);
    });

    test('#isInvert', () {
      expect(MustacheSection.section.isInvert, isFalse);
      expect(MustacheSection.endSection.isInvert, isFalse);
      expect(MustacheSection.invertedSection.isInvert, isTrue);
    });

    group('#symbol', () {
      test('returns the symbol of the start section', () {
        expect(MustacheSection.section.symbol, '#');
      });

      test('returns the symbol of the end section', () {
        expect(MustacheSection.endSection.symbol, '/');
      });

      test('returns the symbol of the invert section', () {
        expect(MustacheSection.invertedSection.symbol, '^');
      });
    });

    group('#format', () {
      const defaultValue = 'hello';

      test('returns the format of the start section', () {
        expect(
          MustacheSection.section.format(defaultValue),
          '{{#$defaultValue}}',
        );
      });

      test('returns the format of the end section', () {
        expect(
          MustacheSection.endSection.format(defaultValue),
          '{{/$defaultValue}}',
        );
      });

      test('returns the format of the invert section', () {
        expect(
          MustacheSection.invertedSection.format(defaultValue),
          '{{^$defaultValue}}',
        );
      });
    });
  });

  group('MustacheSectionList', () {
    const suffix = 'ASDF';

    const sectionsWithoutSuffixes = {
      MustacheSection.section: [
        'section',
      ],
      MustacheSection.invertedSection: [
        'invertedSection',
        'invertedsection',
        'invertSection',
        'invertsection',
      ],
      MustacheSection.endSection: [
        'endSection',
        'endsection',
      ],
    };

    const sectionsWithSuffixes = {
      MustacheSection.section: [
        'section$suffix',
      ],
      MustacheSection.invertedSection: [
        'invertedSection$suffix',
        'invertedsection$suffix',
        'invertSection$suffix',
        'invertsection$suffix',
      ],
      MustacheSection.endSection: [
        'endSection$suffix',
        'endsection$suffix',
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
