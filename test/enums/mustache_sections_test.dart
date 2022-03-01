import 'package:brick_oven/enums/mustache_sections.dart';
import 'package:test/test.dart';

void main() {
  group('$MustacheSections', () {
    group('#configName', () {
      test('returns the name of the start config', () {
        expect(MustacheSections.start.configName, 's');
      });

      test('returns the name of the end config', () {
        expect(MustacheSections.end.configName, 'e');
      });

      test('returns the name of the invert config', () {
        expect(MustacheSections.invert.configName, 'n');
      });
    });

    test('#isStart', () {
      expect(MustacheSections.start.isStart, isTrue);
      expect(MustacheSections.end.isStart, isFalse);
      expect(MustacheSections.invert.isStart, isFalse);
    });

    test('#isEnd', () {
      expect(MustacheSections.start.isEnd, isFalse);
      expect(MustacheSections.end.isEnd, isTrue);
      expect(MustacheSections.invert.isEnd, isFalse);
    });

    test('#isInvert', () {
      expect(MustacheSections.start.isInvert, isFalse);
      expect(MustacheSections.end.isInvert, isFalse);
      expect(MustacheSections.invert.isInvert, isTrue);
    });

    group('#symbol', () {
      test('returns the symbol of the start section', () {
        expect(MustacheSections.start.symbol, '#');
      });

      test('returns the symbol of the end section', () {
        expect(MustacheSections.end.symbol, '/');
      });

      test('returns the symbol of the invert section', () {
        expect(MustacheSections.invert.symbol, '^');
      });
    });

    group('#matcher', () {
      test('returns the matcher of the start section', () {
        expect(MustacheSections.start.matcher, RegExp(r'((?!\w)(\s))?(s)$'));
      });

      test('returns the matcher of the end section', () {
        expect(MustacheSections.end.matcher, RegExp(r'((?!\w)(\s))?(e)$'));
      });

      test('returns the matcher of the invert section', () {
        expect(MustacheSections.invert.matcher, RegExp(r'((?!\w)(\s))?(n)$'));
      });
    });

    group('#format', () {
      const defaultValue = 'hello';
      test('returns the format of the start section', () {
        expect(
          MustacheSections.start.format(defaultValue),
          '{{#$defaultValue}}',
        );
      });

      test('returns the format of the end section', () {
        expect(
          MustacheSections.end.format(defaultValue),
          '{{/$defaultValue}}',
        );
      });

      test('returns the format of the invert section', () {
        expect(
          MustacheSections.invert.format(defaultValue),
          '{{^$defaultValue}}',
        );
      });
    });
  });

  group('MustacheSectionList', () {
    const sections = MustacheSections.values;

    group('#from', () {
      test('returns the $MustacheSections froms string', () {
        final sects = {
          's': MustacheSections.start,
          'e': MustacheSections.end,
          'n': MustacheSections.invert,
          ' s': MustacheSections.start,
          ' e': MustacheSections.end,
          ' n': MustacheSections.invert,
          'a s': MustacheSections.start,
          'a e': MustacheSections.end,
          'a n': MustacheSections.invert,
        };

        for (final sect in sects.entries) {
          expect(sections.from(sect.key), sect.value);
        }
      });
    });

    group('#configNames', () {
      test('returns the config names', () {
        expect(sections.configNames, ['s', 'e', 'n']);
      });
    });

    group('#section', () {
      test('returns the section from the config name', () {
        expect(sections.section('s'), MustacheSections.start);
        expect(sections.section('e'), MustacheSections.end);
        expect(sections.section('n'), MustacheSections.invert);
      });

      test('returns null if the config name is not found', () {
        expect(() => sections.section('x'), throwsStateError);
      });
    });
  });
}
