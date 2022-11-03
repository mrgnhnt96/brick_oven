import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_format.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('$Name', () {
    test('can be instanciated', () {
      expect(() => const Name('name'), returnsNormally);
    });

    group('#from', () {
      test('can parse string when provided', () {
        expect(Name.from('name', 'backup'), equals(const Name('name')));
      });

      test('can parse yaml map when provided', () {
        final yaml = loadYaml('''
value: name
prefix: prefix
suffix: suffix
''') as YamlMap;

        expect(
          Name.from(yaml, 'backup'),
          equals(const Name('name', prefix: 'prefix', suffix: 'suffix')),
        );
      });

      test('should throw $ConfigException when extra keys are provided', () {
        final yaml = loadYaml('''
value: name
prefix: prefix
suffix: suffix
extra: extra
''') as YamlMap;

        expect(
          () => Name.from(yaml, 'backup'),
          throwsA(isA<ConfigException>()),
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

      test('can parse string when provided', () {
        expect(
          Name.fromYamlValue(
            const YamlValue.string('name'),
            'backup',
          ),
          equals(const Name('name')),
        );
      });

      test('can parse yaml map when provided', () {
        final yaml = loadYaml('''
value: name
prefix: prefix
suffix: suffix
''') as YamlMap;

        expect(
          Name.fromYamlValue(YamlValue.yaml(yaml), 'backup'),
          equals(const Name('name', prefix: 'prefix', suffix: 'suffix')),
        );
      });

      test('can parse format when provided', () {
        final yaml = loadYaml('''
value: name
format: snake
''') as YamlMap;

        expect(
          Name.fromYamlValue(YamlValue.yaml(yaml), 'backup'),
          equals(
            const Name(
              'name',
              format: MustacheFormat.snakeCase,
            ),
          ),
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
