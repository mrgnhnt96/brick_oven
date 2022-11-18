import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_tag.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('$Name', () {
    test('can be instanciated', () {
      expect(() => const Name('name'), returnsNormally);
    });

    group('#fromYaml', () {
      test('can parse null and returns backup name', () {
        expect(
          Name.fromYaml(const YamlValue.none(), 'name'),
          const Name('name'),
        );
      });

      test('can parse string when provided', () {
        expect(
          Name.fromYaml(
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
          Name.fromYaml(YamlValue.yaml(yaml), 'backup'),
          equals(const Name('name', prefix: 'prefix', suffix: 'suffix')),
        );
      });

      test('can parse format when provided', () {
        final yaml = loadYaml('''
value: name
format: snake
''') as YamlMap;

        expect(
          Name.fromYaml(YamlValue.yaml(yaml), 'backup'),
          equals(
            const Name(
              'name',
              tag: MustacheTag.snakeCase,
            ),
          ),
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
          () => Name.fromYaml(YamlValue.from(yaml), 'backup'),
          throwsA(isA<ConfigException>()),
        );
      });

      test('should throw $ConfigException when yaml is error', () {
        expect(
          () => Name.fromYaml(const YamlError('error'), 'backup'),
          throwsA(isA<ConfigException>()),
        );
      });

      test('should throw $ConfigException when values are wrong type', () {
        const keys = ['name, prefix, suffix, format'];
        for (final key in keys) {
          final yaml = loadYaml('''
$key:
  key: value
''') as YamlMap;

          expect(
            () => Name.fromYaml(YamlValue.from(yaml), 'backup'),
            throwsA(isA<ConfigException>()),
          );
        }
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
  });
}
