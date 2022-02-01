import 'package:brick_oven/enums/mustache_format.dart';
import 'package:test/test.dart';

void main() {
  group('MustacheFormatX', () {
    group('#toMustache', () {
      test('formats the content correctly', () {
        const format = MustacheFormat.camelCase;
        const content = 'sup_dude';

        expect(
          format.toMustache(content),
          '{{#camelCase}}$content{{/camelCase}}',
        );
      });

      test('uses invert when provided', () {
        const format = MustacheFormat.camelCase;
        const content = 'sup_dude';

        expect(
          format.toMustache(content, invert: true),
          '{{^camelCase}}$content{{/camelCase}}',
        );
      });
    });
  });

  group('EnumListX', () {
    group('#retrieve', () {
      test('returns the value when provided', () {
        final result = MustacheFormat.values.retrieve('camelCase');

        expect(result, MustacheFormat.camelCase);
      });

      test('returns null when not provided', () {
        final result = MustacheFormat.values.retrieve('not_a_format');

        expect(result, isNull);
      });
    });
  });
}
