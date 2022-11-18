import 'package:test/test.dart';

import 'package:brick_oven/enums/mustache_section.dart';

void main() {
  group('$MustacheSection', () {
    group('#configName', () {
      test('returns the name of the start config', () {
        expect(MustacheSection.start.configName, 'start');
      });

      test('returns the name of the end config', () {
        expect(MustacheSection.end.configName, 'end');
      });

      test('returns the name of the invert config', () {
        expect(MustacheSection.invert.configName, 'nstart');
      });
    });

    test('#isStart', () {
      expect(MustacheSection.start.isStart, isTrue);
      expect(MustacheSection.end.isStart, isFalse);
      expect(MustacheSection.invert.isStart, isFalse);
    });

    test('#isEnd', () {
      expect(MustacheSection.start.isEnd, isFalse);
      expect(MustacheSection.end.isEnd, isTrue);
      expect(MustacheSection.invert.isEnd, isFalse);
    });

    test('#isInvert', () {
      expect(MustacheSection.start.isInvert, isFalse);
      expect(MustacheSection.end.isInvert, isFalse);
      expect(MustacheSection.invert.isInvert, isTrue);
    });

    group('#symbol', () {
      test('returns the symbol of the start section', () {
        expect(MustacheSection.start.symbol, '#');
      });

      test('returns the symbol of the end section', () {
        expect(MustacheSection.end.symbol, '/');
      });

      test('returns the symbol of the invert section', () {
        expect(MustacheSection.invert.symbol, '^');
      });
    });

    group('#matcher', () {
      test('returns the matcher of the start section', () {
        expect(
          MustacheSection.start.matcher,
          RegExp(r'((?!\w)(\s))?(start)$'),
        );
      });

      test('returns the matcher of the end section', () {
        expect(MustacheSection.end.matcher, RegExp(r'((?!\w)(\s))?(end)$'));
      });

      test('returns the matcher of the invert section', () {
        expect(
          MustacheSection.invert.matcher,
          RegExp(r'((?!\w)(\s))?(nstart)$'),
        );
      });
    });

    group('#format', () {
      const defaultValue = 'hello';
      test('returns the format of the start section', () {
        expect(
          MustacheSection.start.format(defaultValue),
          '{{#$defaultValue}}',
        );
      });

      test('returns the format of the end section', () {
        expect(
          MustacheSection.end.format(defaultValue),
          '{{/$defaultValue}}',
        );
      });

      test('returns the format of the invert section', () {
        expect(
          MustacheSection.invert.format(defaultValue),
          '{{^$defaultValue}}',
        );
      });
    });
  });

  group('MustacheSectionList', () {
    const sections = MustacheSection.values;

    group('#from', () {
      test('returns the $MustacheSection from strings', () {
        final sects = {
          'start': MustacheSection.start,
          'end': MustacheSection.end,
          'nstart': MustacheSection.invert,
          ' start': MustacheSection.start,
          ' end': MustacheSection.end,
          ' nstart': MustacheSection.invert,
          'a start': MustacheSection.start,
          'a end': MustacheSection.end,
          'a nstart': MustacheSection.invert,
        };

        for (final sect in sects.entries) {
          expect(sections.from(sect.key), sect.value);
        }
      });
    });

    group('#configNames', () {
      test('returns the config names', () {
        expect(sections.configNames, ['start', 'end', 'nstart']);
      });
    });

    group('#section', () {
      test('returns the section from the config name', () {
        expect(sections.section('start'), MustacheSection.start);
        expect(sections.section('end'), MustacheSection.end);
        expect(sections.section('nstart'), MustacheSection.invert);
      });

      test('returns null if the config name is not found', () {
        expect(() => sections.section('x'), throwsStateError);
      });
    });
  });
}
