import 'package:test/test.dart';

import 'package:brick_oven/enums/mustache_loops.dart';

void main() {
  group('$MustacheLoops', () {
    group('#configName', () {
      test('returns the name of the start config', () {
        expect(MustacheLoops.start.configName, 'start');
      });

      test('returns the name of the end config', () {
        expect(MustacheLoops.end.configName, 'end');
      });

      test('returns the name of the invert config', () {
        expect(MustacheLoops.invert.configName, 'nstart');
      });
    });

    test('#isStart', () {
      expect(MustacheLoops.start.isStart, isTrue);
      expect(MustacheLoops.end.isStart, isFalse);
      expect(MustacheLoops.invert.isStart, isFalse);
    });

    test('#isEnd', () {
      expect(MustacheLoops.start.isEnd, isFalse);
      expect(MustacheLoops.end.isEnd, isTrue);
      expect(MustacheLoops.invert.isEnd, isFalse);
    });

    test('#isInvert', () {
      expect(MustacheLoops.start.isInvert, isFalse);
      expect(MustacheLoops.end.isInvert, isFalse);
      expect(MustacheLoops.invert.isInvert, isTrue);
    });

    group('#symbol', () {
      test('returns the symbol of the start section', () {
        expect(MustacheLoops.start.symbol, '#');
      });

      test('returns the symbol of the end section', () {
        expect(MustacheLoops.end.symbol, '/');
      });

      test('returns the symbol of the invert section', () {
        expect(MustacheLoops.invert.symbol, '^');
      });
    });

    group('#matcher', () {
      test('returns the matcher of the start section', () {
        expect(MustacheLoops.start.matcher, RegExp(r'((?!\w)(\s))?(start)$'));
      });

      test('returns the matcher of the end section', () {
        expect(MustacheLoops.end.matcher, RegExp(r'((?!\w)(\s))?(end)$'));
      });

      test('returns the matcher of the invert section', () {
        expect(MustacheLoops.invert.matcher, RegExp(r'((?!\w)(\s))?(nstart)$'));
      });
    });

    group('#format', () {
      const defaultValue = 'hello';
      test('returns the format of the start section', () {
        expect(
          MustacheLoops.start.format(defaultValue),
          '{{#$defaultValue}}',
        );
      });

      test('returns the format of the end section', () {
        expect(
          MustacheLoops.end.format(defaultValue),
          '{{/$defaultValue}}',
        );
      });

      test('returns the format of the invert section', () {
        expect(
          MustacheLoops.invert.format(defaultValue),
          '{{^$defaultValue}}',
        );
      });
    });
  });

  group('MustacheSectionList', () {
    const sections = MustacheLoops.values;

    group('#from', () {
      test('returns the $MustacheLoops from strings', () {
        final sects = {
          'start': MustacheLoops.start,
          'end': MustacheLoops.end,
          'nstart': MustacheLoops.invert,
          ' start': MustacheLoops.start,
          ' end': MustacheLoops.end,
          ' nstart': MustacheLoops.invert,
          'a start': MustacheLoops.start,
          'a end': MustacheLoops.end,
          'a nstart': MustacheLoops.invert,
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
        expect(sections.section('start'), MustacheLoops.start);
        expect(sections.section('end'), MustacheLoops.end);
        expect(sections.section('nstart'), MustacheLoops.invert);
      });

      test('returns null if the config name is not found', () {
        expect(() => sections.section('x'), throwsStateError);
      });
    });
  });
}
