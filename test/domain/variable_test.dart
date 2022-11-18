import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_format.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('can be instanciated', () {
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

    test('returns successfully when string provided', () {
      const expected = Variable(name: 'scooby_doo', placeholder: '_PET_');

      expect(
        Variable.fromYaml(const YamlValue.string('_PET_'), 'scooby_doo'),
        expected,
      );
    });

    test('returns successfully when null provided', () {
      const expected = Variable(name: 'scooby_doo', placeholder: 'scooby_doo');

      expect(
        Variable.fromYaml(const YamlValue.none(), 'scooby_doo'),
        expected,
      );
    });
  });

  group('#formatName', () {
    test('returns the formatted name', () {
      const variable = Variable(name: 'scooby_doo');

      expect(
        variable.formatName(MustacheFormat.camelCase),
        '{{#camelCase}}{{{scooby_doo}}}{{/camelCase}}',
      );
    });
  });
}
