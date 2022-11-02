import 'package:test/test.dart';

import 'package:brick_oven/enums/mustache_format.dart';

void main() {
  group('MustacheFormatX', () {
    group('#toMustache', () {
      test('throws assertion when content is not wrapped with brackets', () {
        expect(
          () => MustacheFormat.camelCase.toMustache('content'),
          throwsA(isA<AssertionError>()),
        );
      });

      test('formats the content correctly', () {
        for (final format in MustacheFormat.values) {
          const content = '{{{sup_dude}}}';

          if (format.isEscape) {
            expect(
              format.toMustache(content),
              content,
            );
            continue;
          }

          expect(
            format.toMustache(content),
            '{{#${format.name}}}$content{{/${format.name}}}',
          );
        }
      });
    });
  });

  group('ListX', () {
    group('#retrieve', () {
      test('enum returns the value when provided', () {
        final result = MustacheFormat.values.retrieve('camelCase');

        expect(result, MustacheFormat.camelCase);
      });

      test('string returns the value when provided', () {
        const search = 'num';
        final result = ['val', search].retrieve(search);

        expect(result, search);
      });

      test('int returns the value when provided', () {
        const search = 1;
        final result = [2, search].retrieve(search);

        expect(result, search);
      });

      test('returns null when not provided', () {
        final result = MustacheFormat.values.retrieve('not_a_format');

        expect(result, isNull);
      });
    });
  });
}
