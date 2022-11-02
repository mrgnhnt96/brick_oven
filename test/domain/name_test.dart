import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_format.dart';
import 'package:test/test.dart';

import '../utils/fakes.dart';

void main() {
  group('$Name', () {
    test('can be instanciated', () {
      expect(() => const Name('name'), returnsNormally);
    });

    group('#from', () {
      test('throws $ArgumentError when null is provided without backup name',
          () {
        expect(() => Name.from(null), throwsArgumentError);
      });

      test('can parse string when provided', () {
        expect(Name.from('name'), equals(const Name('name')));
      });

      test('can parse yaml map when provided', () {
        expect(
          Name.from(
            FakeYamlMap(<String, dynamic>{
              'value': 'name',
              'prefix': 'prefix',
              'suffix': 'suffix',
            }),
          ),
          equals(const Name('name', prefix: 'prefix', suffix: 'suffix')),
        );
      });

      test('throws $ArgumentError when name is null', () {
        expect(
          () => Name.from(
            FakeYamlMap(<String, dynamic>{
              'value': null,
              'prefix': 'prefix',
              'suffix': 'suffix',
            }),
          ),
          throwsArgumentError,
        );
      });
    });

    group('#fromYamlValue', () {
      test('can parse null and returns backup name', () {
        expect(
          Name.fromYamlValue(const YamlValue.none(), 'name'),
          const Name('name'),
        );
      });

      test('throws $ArgumentError when null is provided without backup name',
          () {
        expect(
          () => Name.fromYamlValue(const YamlValue.none()),
          throwsArgumentError,
        );
      });

      test('can parse string when provided', () {
        expect(
          Name.fromYamlValue(const YamlValue.string('name')),
          equals(const Name('name')),
        );
      });

      test('can parse yaml map when provided', () {
        expect(
          Name.fromYamlValue(
            YamlValue.yaml(
              FakeYamlMap(<String, dynamic>{
                'value': 'name',
                'prefix': 'prefix',
                'suffix': 'suffix',
              }),
            ),
          ),
          equals(const Name('name', prefix: 'prefix', suffix: 'suffix')),
        );
      });

      test('can parse format when provided', () {
        expect(
          Name.fromYamlValue(
            YamlValue.yaml(
              FakeYamlMap(<String, dynamic>{
                'value': 'name',
                'format': 'snake',
              }),
            ),
          ),
          equals(
            const Name(
              'name',
              format: MustacheFormat.snakeCase,
            ),
          ),
        );
      });

      test('throws $ArgumentError when name is null', () {
        expect(
          () => Name.from(
            FakeYamlMap(<String, dynamic>{
              'value': null,
              'prefix': 'prefix',
              'suffix': 'suffix',
            }),
          ),
          throwsArgumentError,
        );
      });
    });

    group('#simple', () {
      test('formats and prepends the prefix and appends the suffix', () {
        expect(
          const Name('name', prefix: 'prefix', suffix: 'suffix').simple,
          equals('prefix{name}suffix'),
        );
      });
    });

    group('#format', () {
      test('prepends the prefix and appends the suffix', () {
        expect(
          const Name('name', prefix: 'prefix', suffix: 'suffix')
              .formatWith(MustacheFormat.camelCase),
          contains('prefix{{{name}}}suffix'),
        );
      });

      test('formats the with the mustache format', () {
        expect(
          const Name('name', prefix: 'prefix', suffix: 'suffix')
              .formatWith(MustacheFormat.snakeCase),
          equals('{{#snakeCase}}prefix{{{name}}}suffix{{/snakeCase}}'),
        );
      });
    });
  });
}
