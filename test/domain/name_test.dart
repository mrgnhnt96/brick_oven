import 'package:test/test.dart';

import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_format.dart';
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
              .format(MustacheFormat.camelCase),
          contains('prefix{{{name}}}suffix'),
        );
      });

      test('formats the with the mustache format', () {
        expect(
          const Name('name', prefix: 'prefix', suffix: 'suffix')
              .format(MustacheFormat.snakeCase),
          equals('{{#snakeCase}}prefix{{{name}}}suffix{{/snakeCase}}'),
        );
      });
    });

    group('#props', () {
      late Name name;

      setUp(() {
        name = const Name(
          'name',
          prefix: 'prefix',
          suffix: 'suffix',
        );
      });

      test('length should be 3', () {
        expect(name.props.length, equals(3));
      });

      test('should contain value', () {
        expect(name.props.contains('name'), isTrue);
      });

      test('should contain prefix', () {
        expect(name.props.contains('prefix'), isTrue);
      });

      test('should contain suffix', () {
        expect(name.props.contains('suffix'), isTrue);
      });
    });
  });
}
