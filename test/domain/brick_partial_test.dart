import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:test/test.dart';
import 'package:brick_oven/domain/brick_partial.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('can be instanciated', () {
    expect(() => const BrickPartial(path: 'path'), returnsNormally);
  });

  group('#fromYaml', () {
    test('throws $ConfigException if yaml is error', () {
      expect(
        () => BrickPartial.fromYaml(const YamlError('err'), 'path'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('returns $BrickPartial when yaml is null', () {
      expect(
        BrickPartial.fromYaml(const YamlNone(), 'path'),
        const BrickPartial(path: 'path'),
      );
    });

    test('returns $BrickPartial when yaml is invalid', () {
      expect(
        () => BrickPartial.fromYaml(const YamlString('hiii'), 'path'),
        throwsA(isA<ConfigException>()),
      );
    });

    group('#vars', () {
      test('throws $ConfigException if yaml is error', () {
        const content = '''
vars: ${1}
''';
        final yaml = YamlValue.from(loadYaml(content));
        expect(
          () => BrickPartial.fromYaml(yaml, 'path'),
          throwsA(isA<ConfigException>()),
        );
      });

      test('throws $ConfigException if yaml is not map', () {
        const content = '''
vars: hiii
''';
        final yaml = YamlValue.from(loadYaml(content));
        expect(
          () => BrickPartial.fromYaml(yaml, 'path'),
          throwsA(isA<ConfigException>()),
        );
      });

      test('throws $ConfigException if var is invalid', () {
        const content = '''
vars:
  some: ${1}
''';
        final yaml = YamlValue.from(loadYaml(content));
        expect(
          () => BrickPartial.fromYaml(yaml, 'path'),
          throwsA(isA<ConfigException>()),
        );
      });

      test('returns $BrickPartial when vars is null', () {
        const content = '''
vars:
''';
        final yaml = YamlValue.from(loadYaml(content));
        expect(
          BrickPartial.fromYaml(yaml, 'path'),
          const BrickPartial(path: 'path'),
        );
      });

      test('returns $BrickPartial when vars are valid', () {
        const content = '''
vars:
  some:
  one: _ONE_

''';
        final yaml = YamlValue.from(loadYaml(content));
        expect(
          BrickPartial.fromYaml(yaml, 'path'),
          const BrickPartial(
            path: 'path',
            variables: [
              Variable(name: 'some'),
              Variable(name: 'one', placeholder: '_ONE_'),
            ],
          ),
        );
      });
    });
  });
}
