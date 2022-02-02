import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/enums/mustache_format.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

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
        'format': format?.name,
        'suffix': suffix,
        'prefix': prefix,
      };
    }

    test('parses everything when provided', () {
      final map = json(
        placeholder: 'placeholder',
        format: MustacheFormat.camelCase,
        suffix: 'suffix',
        prefix: 'prefix',
      );

      final variable = variableFromJson(map);

      expect(variable, isNotNull);
    });

    test('parses everything except for format', () {
      final map = json(
        placeholder: 'placeholder',
        suffix: 'suffix',
        prefix: 'prefix',
      );

      final variable = variableFromJson(map);

      expect(variable.format, MustacheFormat.camelCase);
    });

    test('parses everything except for suffix', () {
      final map = json(
        placeholder: 'placeholder',
        format: MustacheFormat.camelCase,
        prefix: 'prefix',
      );

      final variable = variableFromJson(map);

      expect(variable.suffix, isEmpty);
    });

    test('parses everything except for prefix', () {
      final map = json(
        placeholder: 'placeholder',
        format: MustacheFormat.camelCase,
        suffix: 'suffix',
      );

      final variable = variableFromJson(map);

      expect(variable.prefix, isEmpty);
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

  group('#prefix', () {
    test('returns the prefix', () {
      final variable = variableWithFixes(prefix: 'prefix');

      expect(variable.prefix, 'prefix');
    });

    test('returns empty string when not provided', () {
      final variable = variableWithFixes();

      expect(variable.prefix, isEmpty);
    });
  });

  group('#suffix', () {
    test('returns the suffix', () {
      final variable = variableWithFixes(suffix: 'suffix');

      expect(variable.suffix, 'suffix');
    });

    test('returns empty string when not provided', () {
      final variable = variableWithFixes();

      expect(variable.suffix, isEmpty);
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
        'format': MustacheFormat.camelCase.name,
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

  test('#formattedName return the name with the provided format', () {
    final variable = variableWithFixes();

    expect(variable.formattedName, '{{#camelCase}}{{{$name}}}{{/camelCase}}');
  });
}

class FakeYamlMap extends Fake implements YamlMap {
  FakeYamlMap(Map<String, dynamic> value) : _map = value;

  final Map<String, dynamic> _map;

  @override
  Map get value => _map;
}