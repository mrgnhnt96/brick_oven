import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_format.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('can be instanciated', () {
    const instance = Variable(name: 'Scooby Doo', placeholder: 'placeholder');

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

    test('returns successfully when string provided', () {
      const expected = Variable(name: 'Scooby Doo', placeholder: '_PET_');

      expect(
        Variable.fromYaml(const YamlValue.string('_PET_'), 'Scooby Doo'),
        expected,
      );
    });
  });

  group('#formatName', () {
    test('returns the formatted name', () {
      const variable = Variable(name: 'Scooby Doo');

      expect(
        variable.formatName(MustacheFormat.camelCase),
        '{{#camelCase}}{{{Scooby Doo}}}{{/camelCase}}',
      );
    });
  });
}
