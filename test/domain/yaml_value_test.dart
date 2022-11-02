// ignore_for_file: prefer_void_to_null

import 'package:test/test.dart';

import 'package:brick_oven/domain/yaml_value.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('#string can be instanciated', () {
    const string = YamlValue.string('test');

    expect(string, isA<YamlValue>());
    expect(string, isA<YamlString>());
  });

  test('#error can be instanciated', () {
    const error = YamlValue.error('test');

    expect(error, isA<YamlValue>());
    expect(error, isA<YamlError>());
  });

  test('#list can be instanciated', () {
    final list = YamlValue.list(YamlList());

    expect(list, isA<YamlValue>());
    expect(list, isA<YamlListValue>());
  });

  test('#yaml can be instanciated', () {
    final yaml = YamlValue.yaml(YamlMap());

    expect(yaml, isA<YamlValue>());
    expect(yaml, isA<YamlMapValue>());
  });

  test('#none can be instanciated', () {
    const none = YamlValue.none();

    expect(none, isA<YamlValue>());
    expect(none, isA<YamlNone>());
  });

  group('#from', () {
    test('can receive a string', () {
      const data = 'test';
      final value = YamlValue.from(data);

      expect(value, isA<YamlValue>());
      expect(value, isA<YamlString>());
      expect(value.value, data);
    });

    test('can receive a yaml', () {
      final data = loadYaml('data: data');
      final value = YamlValue.from(data);

      expect(value, isA<YamlValue>());
      expect(value, isA<YamlMapValue>());
      expect(value.value, data);
    });

    test('can receive a null', () {
      const Null data = null;
      final value = YamlValue.from(data);

      expect(value, isA<YamlValue>());
      expect(value, isA<YamlNone>());
      expect(value.value, data);
    });

    test('should be type error when parsing is not successful', () {
      final data = <String, dynamic>{};

      expect(YamlValue.from(data), isA<YamlError>());
    });
  });

  group('#isString', () {
    test('returns true when provided a string', () {
      final value = YamlValue.from('test');

      expect(value.isString(), isTrue);
    });

    test('returns false when provided a non-string', () {
      final value = YamlValue.from(YamlMap());

      expect(value.isString(), isFalse);
    });
  });

  group('#isYaml', () {
    test('returns true when provided a yaml', () {
      final value = YamlValue.from(YamlMap());

      expect(value.isYaml(), isTrue);
    });

    test('returns false when provided a non-yaml', () {
      final value = YamlValue.from('test');

      expect(value.isYaml(), isFalse);
    });
  });

  group('#isList', () {
    test('returns true when provided a list', () {
      final value = YamlValue.from(YamlList());

      expect(value.isList(), isTrue);
    });

    test('returns false when provided a non-list', () {
      final value = YamlValue.from('test');

      expect(value.isList(), isFalse);
    });
  });

  group('#isError', () {
    test('returns true when provided an error', () {
      const value = YamlValue.error('test');

      expect(value.isError(), isTrue);
    });

    test('returns false when provided a non-error', () {
      final value = YamlValue.from('test');

      expect(value.isError(), isFalse);
    });
  });

  group('#isNone', () {
    test('returns true when provided a null', () {
      final value = YamlValue.from(null);

      expect(value.isNone(), isTrue);
    });

    test('returns false when provided a value', () {
      final value = YamlValue.from('test');

      expect(value.isNone(), isFalse);
    });
  });

  group('#asString', () {
    test('should return as $YamlString when value is string', () {
      final value = YamlValue.from('test');

      expect(value.asString(), isA<YamlString>());
    });

    test('should throw when value is not string', () {
      final value = YamlValue.from(YamlMap());

      expect(value.asString, throwsA(isA<ArgumentError>()));
    });
  });

  group('#asError', () {
    test('should return as $YamlError when value is error', () {
      const value = YamlValue.error('test');

      expect(value.asError(), isA<YamlError>());
    });

    test('should throw when value is not error', () {
      final value = YamlValue.from(YamlMap());

      expect(value.asError, throwsA(isA<ArgumentError>()));
    });
  });

  group('#asList', () {
    test('should return as $YamlListValue when value is list', () {
      final value = YamlValue.from(YamlList());

      expect(value.asList(), isA<YamlListValue>());
    });

    test('should throw when value is not list', () {
      final value = YamlValue.from('test');

      expect(value.asList, throwsA(isA<ArgumentError>()));
    });
  });

  group('#asYaml', () {
    test('should return as $YamlMapValue when value is yaml', () {
      final value = YamlValue.from(YamlMap());

      expect(value.asYaml(), isA<YamlMapValue>());
    });

    test('should throw when value is not yaml', () {
      final value = YamlValue.from('test');

      expect(value.asYaml, throwsA(isA<ArgumentError>()));
    });
  });

  group('#asNone', () {
    test('should return as $YamlNone when value is null', () {
      final value = YamlValue.from(null);

      expect(value.asNone(), isA<YamlNone>());
    });

    test('should throw when value is not null', () {
      final value = YamlValue.from('test');

      expect(value.asNone, throwsA(isA<ArgumentError>()));
    });
  });

  group('$YamlString', () {
    test('can be instanciated', () {
      const string = YamlString('test');

      expect(string, isA<YamlString>());
    });

    test('is type $YamlValue', () {
      const string = YamlString('test');

      expect(string, isA<YamlValue>());
    });

    test('value is type String', () {
      const string = YamlString('test');

      expect(string.value, isA<String>());
    });
  });

  group('$YamlMapValue', () {
    test('can be instanciated', () {
      final yaml = YamlMap();

      final value = YamlMapValue(yaml);

      expect(value, isA<YamlMapValue>());
    });

    test('is type $YamlValue', () {
      final yaml = YamlMap();

      final value = YamlMapValue(yaml);

      expect(value, isA<YamlValue>());
    });

    test('value is type $YamlMap', () {
      final yaml = YamlMap();

      final value = YamlMapValue(yaml);

      expect(value.value, isA<YamlMap>());
    });
  });

  group('$YamlNone', () {
    test('can be instanciated', () {
      const none = YamlNone();

      expect(none, isA<YamlNone>());
    });

    test('is type $YamlValue', () {
      const none = YamlNone();

      expect(none, isA<YamlValue>());
    });

    test('value is type null', () {
      const none = YamlNone();

      expect(none.value, isA<Null>());
    });
  });
}
