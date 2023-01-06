import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_tag.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/constants.dart';

void main() {
  group('$Name', () {
    test('can be instantiated', () {
      expect(() => Name('name'), returnsNormally);
    });

    group('throws assertion error', () {
      test('when braces is not 2 or 3', () {
        expect(
          () => Name('name', braces: 1),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => Name('name', braces: 4),
          throwsA(isA<AssertionError>()),
        );
      });

      test('when tag is not a format tag', () {
        expect(
          () => Name('name', tag: MustacheTag.if_),
          throwsA(isA<AssertionError>()),
        );
      });

      test('when section and invertedSection are both set', () {
        expect(
          () => Name('name', section: 'section', invertedSection: 'section'),
          throwsA(isA<AssertionError>()),
        );
      });

      test(
          'when value is $kIndexValue and section and invertedSection are not set',
          () {
        expect(
          () => Name(kIndexValue),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('returns normally', () {
      test('when tag is set and section or invertedSection is set', () {
        expect(
          () => Name('name', tag: MustacheTag.camelCase, section: 'section'),
          returnsNormally,
        );

        expect(
          () => Name(
            'name',
            tag: MustacheTag.camelCase,
            invertedSection: 'section',
          ),
          returnsNormally,
        );
      });
    });

    group('#fromYaml', () {
      test('can parse null and returns backup name', () {
        expect(
          Name.fromYaml(const YamlValue.none(), 'name'),
          Name('name'),
        );
      });

      test('can parse string', () {
        expect(
          Name.fromYaml(
            const YamlValue.string('name'),
            'backup',
          ),
          Name('name'),
        );
      });

      test('can parse yaml map with section', () {
        final yaml = loadYaml('''
value: name
prefix: prefix
suffix: suffix
section: section
''') as YamlMap;

        expect(
          Name.fromYaml(YamlValue.yaml(yaml), 'backup'),
          Name(
            'name',
            prefix: 'prefix',
            suffix: 'suffix',
            section: 'section',
          ),
        );
      });

      test('can parse yaml map with inverted_section', () {
        final yaml = loadYaml('''
value: name
prefix: prefix
suffix: suffix
inverted_section: invertedSection
''') as YamlMap;

        expect(
          Name.fromYaml(YamlValue.yaml(yaml), 'backup'),
          Name(
            'name',
            prefix: 'prefix',
            suffix: 'suffix',
            invertedSection: 'invertedSection',
          ),
        );
      });

      test('can parse yaml map with invert_section', () {
        final yaml = loadYaml('''
value: name
prefix: prefix
suffix: suffix
invert_section: invertedSection
''') as YamlMap;

        expect(
          Name.fromYaml(YamlValue.yaml(yaml), 'backup'),
          Name(
            'name',
            prefix: 'prefix',
            suffix: 'suffix',
            invertedSection: 'invertedSection',
          ),
        );
      });

      group('sections', () {
        test('can parse section', () {
          final yaml = loadYaml('''
value: name
section: section
''') as YamlMap;

          expect(
            Name.fromYaml(YamlValue.yaml(yaml), 'backup'),
            Name('name', section: 'section'),
          );
        });

        test('can parse inverted section', () {
          final yaml = loadYaml('''
value: name
inverted_section: inverted_section
''') as YamlMap;

          expect(
            Name.fromYaml(YamlValue.yaml(yaml), 'backup'),
            Name('name', invertedSection: 'inverted_section'),
          );
        });

        test(
            'should throw $VariableException when section and inverted section are provided',
            () {
          final yaml = loadYaml('''
value: name
section: section
inverted_section: inverted_section
''') as YamlMap;

          expect(
            () => Name.fromYaml(YamlValue.yaml(yaml), 'backup'),
            throwsA(isA<VariableException>()),
          );
        });

        test('should return normally when format and section are provided', () {
          final yaml = loadYaml('''
value: name
format: camel
section: section
''') as YamlMap;

          expect(
            () => Name.fromYaml(YamlValue.yaml(yaml), 'backup'),
            returnsNormally,
          );
        });

        test(
            'should return normally when format and inverted section are provided',
            () {
          final yaml = loadYaml('''
value: name
format: camel
inverted_section: section
''') as YamlMap;

          expect(
            () => Name.fromYaml(YamlValue.yaml(yaml), 'backup'),
            returnsNormally,
          );
        });
      });

      group('braces', () {
        test('can parse', () {
          final yaml = loadYaml('''
value: name
braces: 3
''') as YamlMap;

          expect(
            Name.fromYaml(YamlValue.yaml(yaml), 'backup'),
            equals(Name('name', braces: 3)),
          );
        });

        test('can parse when omitted', () {
          final yaml = loadYaml('''
value: name
braces:
''') as YamlMap;

          expect(
            Name.fromYaml(YamlValue.yaml(yaml), 'backup'),
            equals(Name('name', braces: 3)),
          );
        });

        test('throws $VariableException when braces is not 2 or 3', () {
          final yaml = loadYaml('''
value: name
braces: 1
''') as YamlMap;

          expect(
            () => Name.fromYaml(YamlValue.yaml(yaml), 'backup'),
            throwsA(isA<VariableException>()),
          );
        });
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

    group('#format', () {
      test('wraps with provided braces', () {
        expect(
          Name('name', braces: 2).format(),
          '{{name}}',
        );

        expect(
          Name('name', braces: 3).format(),
          '{{{name}}}',
        );
      });

      test('includes prefix', () {
        expect(
          Name('name', prefix: 'prefix').format(),
          'prefix{{{name}}}',
        );
      });

      test('includes suffix', () {
        expect(
          Name('name', suffix: 'suffix').format(),
          '{{{name}}}suffix',
        );
      });

      test('wraps with section', () {
        expect(
          Name('name', section: 'section').format(),
          '{{#section}}{{{name}}}{{/section}}',
        );
      });

      test('wraps with inverted section', () {
        expect(
          Name('name', invertedSection: 'section').format(),
          '{{^section}}{{{name}}}{{/section}}',
        );
      });

      test('converted $kIndexValue to correct format', () {
        expect(
          Name(kIndexValue, invertedSection: 'section').format(),
          '{{^section}}{{{.}}}{{/section}}',
        );
        expect(
          Name(kIndexValue, section: 'section').format(),
          '{{#section}}{{{.}}}{{/section}}',
        );
      });

      test('wraps with braces by default', () {
        expect(
          Name('name').format(),
          '{{{name}}}',
        );
      });

      test('wraps with format', () {
        expect(
          Name('name', tag: MustacheTag.camelCase).format(),
          '{{#camelCase}}{{{name}}}{{/camelCase}}',
        );
      });

      test('wraps with format and section', () {
        expect(
          Name('name', tag: MustacheTag.camelCase, section: 'section').format(),
          '{{#section}}{{#camelCase}}{{{name}}}{{/camelCase}}{{/section}}',
        );
      });

      test('wraps with format and inverted section', () {
        expect(
          Name('name', tag: MustacheTag.camelCase, invertedSection: 'section')
              .format(),
          '{{^section}}{{#camelCase}}{{{name}}}{{/camelCase}}{{/section}}',
        );
      });

      test('wraps prefix/suffix with format and section', () {
        expect(
          Name(
            'name',
            tag: MustacheTag.camelCase,
            section: 'section',
            prefix: 'prefix',
            suffix: 'suffix',
          ).format(),
          '{{#section}}prefix{{#camelCase}}{{{name}}}{{/camelCase}}suffix{{/section}}',
        );
      });

      test('wraps prefix/suffix with format and inverted section', () {
        final name = Name(
          'name',
          tag: MustacheTag.camelCase,
          invertedSection: 'section',
          prefix: 'prefix',
          suffix: 'suffix',
        );

        expect(
          name.format(),
          '{{^section}}prefix{{#camelCase}}{{{name}}}{{/camelCase}}suffix{{/section}}',
        );
      });

      test('wraps appends trailing before wrapping with section', () {
        final name = Name(
          'name',
          tag: MustacheTag.camelCase,
          invertedSection: 'section',
          prefix: 'prefix',
          suffix: 'suffix',
        );

        expect(
          name.format(trailing: '.dart'),
          '{{^section}}prefix{{#camelCase}}{{{name}}}{{/camelCase}}suffix.dart{{/section}}',
        );
      });

      test(
          'wraps adds postStartBraces & preEndBraces before wrapping with format',
          () {
        final name = Name(
          'name',
          tag: MustacheTag.camelCase,
          invertedSection: 'section',
          prefix: 'prefix',
          suffix: 'suffix',
        );

        expect(
          name.format(postStartBraces: '% ', preEndBraces: ' %'),
          '{{^section}}prefix{{#camelCase}}{{{% name %}}}{{/camelCase}}suffix{{/section}}',
        );
      });
    });
  });
}
