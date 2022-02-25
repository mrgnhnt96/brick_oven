import 'package:test/test.dart';

import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/enums/mustache_format.dart';
import '../utils/fakes.dart';
import '../utils/to_yaml.dart';

void main() {
  const name = 'scooby-doo';

  Variable variableWithFixes({
    String? prefix,
    String? suffix,
  }) {
    final map = {
      'suffix': suffix,
      'prefix': prefix,
    };
    final yaml = FakeYamlMap(map);

    return Variable.fromYaml(name, yaml);
  }

  Variable variableFromJson(Map<String, dynamic> json) {
    final yaml = FakeYamlMap(json);

    return Variable.fromYaml(name, yaml);
  }

  test('can be instanciated', () {
    const instance = Variable(name: name, placeholder: 'placeholder');

    expect(instance, isNotNull);
  });

  group('#fromYaml', () {
    Map<String, dynamic> json({
      String? placeholder,
      MustacheFormat? format,
      String? suffix,
      String? prefix,
    }) {
      return <String, dynamic>{
        'placeholder': placeholder,
        'suffix': suffix,
        'prefix': prefix,
      };
    }

    test('parses everything when provided', () {
      const variable = Variable(
        name: name,
        placeholder: 'placeholder',
        suffix: 'suffix',
        prefix: 'prefix',
      );

      final yaml = variable.toJson();

      final result = variableFromJson(yaml);

      expect(result, variable);
    });

    test('parses everything except for suffix', () {
      final map = json(
        placeholder: 'placeholder',
        format: MustacheFormat.camelCase,
        prefix: 'prefix',
      );

      final variable = variableFromJson(map);

      expect(variable.suffix, isNull);
    });

    test('parses everything except for prefix', () {
      final map = json(
        placeholder: 'placeholder',
        format: MustacheFormat.camelCase,
        suffix: 'suffix',
      );

      final variable = variableFromJson(map);

      expect(variable.prefix, isNull);
    });

    test('parses everything except for placeholder', () {
      final map = json(
        format: MustacheFormat.camelCase,
        suffix: 'suffix',
        prefix: 'prefix',
      );

      final variable = variableFromJson(map);

      expect(variable.placeholder, name);
    });

    test('throws argument error when extra keys are provided', () {
      final map = json(
        placeholder: 'placeholder',
        format: MustacheFormat.camelCase,
        suffix: 'suffix',
        prefix: 'prefix',
      );

      map['extra'] = 'extra';

      expect(() => variableFromJson(map), throwsArgumentError);
    });
  });

  group('#from', () {
    test('can parse null when provided', () {
      expect(() => Variable.from('', null), returnsNormally);
    });

    test('can parse String when provided', () {
      expect(() => Variable.from('', 'value'), returnsNormally);
    });

    test('can parse yamlMap when provided', () {
      expect(
        () => Variable.from(
          '',
          FakeYamlMap(<String, dynamic>{'placeholder': 'name'}),
        ),
        returnsNormally,
      );
    });
  });

  group('#prefix', () {
    test('returns the prefix', () {
      final variable = variableWithFixes(prefix: 'prefix');

      expect(variable.prefix, 'prefix');
    });

    test('returns nothing when not provided', () {
      final variable = variableWithFixes();

      expect(variable.prefix, isNull);
    });
  });

  group('#suffix', () {
    test('returns the suffix', () {
      final variable = variableWithFixes(suffix: 'suffix');

      expect(variable.suffix, 'suffix');
    });

    test('returns nothing when not provided', () {
      final variable = variableWithFixes();

      expect(variable.suffix, isNull);
    });
  });

  group('#formatName', () {
    Variable getVariable({
      String? prefix,
      String? suffix,
    }) {
      final map = {
        'placeholder': name,
        'suffix': suffix,
        'prefix': prefix,
      };

      return variableFromJson(map);
    }

    test('returns the formatted name', () {
      final variable = getVariable();

      expect(
        variable.formatName(MustacheFormat.camelCase),
        '{{#camelCase}}{{{$name}}}{{/camelCase}}',
      );
    });

    test('starts with the prefix', () {
      const prefix = 'prefix';

      final variable = getVariable(prefix: prefix);

      expect(
        variable.formatName(MustacheFormat.camelCase),
        startsWith('{{#camelCase}}$prefix'),
      );
    });

    test('ends with the suffix', () {
      const suffix = 'suffix';

      final variable = getVariable(suffix: suffix);

      expect(
        variable.formatName(MustacheFormat.camelCase),
        endsWith('$suffix{{/camelCase}}'),
      );
    });
  });
}
