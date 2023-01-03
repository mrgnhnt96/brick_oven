import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('can be instantiated', () {
    const instance = Variable(name: 'scooby_doo', placeholder: 'placeholder');

    expect(instance, isNotNull);
  });

  group('#fromYaml', () {
    test('throws $ConfigException when incorrect type', () {
      final yaml = loadYaml('''
key: value
''');

      expect(
        () => Variable.fromYaml(YamlValue.from(yaml), ''),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws $ConfigException when yaml is error', () {
      expect(
        () => Variable.fromYaml(const YamlValue.error('error'), ''),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws $ConfigException when placeholder or name contains whitespace',
        () {
      const throwValues = [
        'some text',
        'just - testing',
        'just\ntesting',
        'just\ttesting',
      ];

      for (final value in throwValues) {
        expect(
          () => Variable.fromYaml(YamlValue.from(value), ''),
          throwsA(isA<ConfigException>()),
        );

        expect(
          () => Variable.fromYaml(YamlValue.from('alright'), value),
          throwsA(isA<ConfigException>()),
        );
      }

      expect(
        () => Variable.fromYaml(YamlValue.from(''), ''),
        returnsNormally,
      );
    });

    test('returns successfully when string provided', () {
      const successValues = [
        '',
        'this',
        'this-is',
        r'<>(){}[].-_+=!@#\$%^&*',
      ];

      for (final value in successValues) {
        expect(
          () => Variable.fromYaml(YamlValue.from(value), ''),
          returnsNormally,
        );

        expect(
          () => Variable.fromYaml(const YamlValue.none(), value),
          returnsNormally,
        );
      }
    });

    test('returns successfully when null provided', () {
      const expected = Variable(name: 'scooby_doo', placeholder: 'scooby_doo');

      expect(
        Variable.fromYaml(const YamlValue.none(), 'scooby_doo'),
        expected,
      );
    });
  });
}
