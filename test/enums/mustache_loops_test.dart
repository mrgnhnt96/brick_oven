import 'package:test/test.dart';

import 'package:brick_oven/enums/mustache_loops.dart';

void main() {
  group('$MustacheLoops', () {
    test('#start returns the correct value', () {
      expect(MustacheLoops.start, 'start');
    });

    test('#end returns the correct value', () {
      expect(MustacheLoops.end, 'end');
    });

    test('#startInvert returns the correct value', () {
      expect(MustacheLoops.startInvert, 'nstart');
    });

    group('#toMustache', () {
      const key = 'purple';

      test('returns the correct value for start', () {
        expect(
          MustacheLoops.toMustache(key, MustacheLoops.start),
          '{{#$key}}',
        );
      });

      test('returns the correct value for end', () {
        expect(
          MustacheLoops.toMustache(key, MustacheLoops.startInvert),
          '{{^$key}}',
        );
      });

      test('returns the correct value for startInvert', () {
        expect(
          MustacheLoops.toMustache(key, MustacheLoops.end),
          '{{/$key}}',
        );
      });

      test('throws when given an invalid value', () {
        expect(
          () => MustacheLoops.toMustache(key, 'invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
