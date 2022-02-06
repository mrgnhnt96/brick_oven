// ignore_for_file: overridden_fields

import 'package:yaml/yaml.dart';

/// {@template yaml_value}
/// Represents the value of a key from a Yaml file
/// {@endtemplate}
abstract class YamlValue {
  /// {@macro yaml_value}
  const YamlValue(this.value);

  /// {@macro yaml_value}
  ///
  /// Represents the value as a `String`
  const factory YamlValue.string(String value) = YamlString;

  /// {@macro yaml_value}
  ///
  /// represents the value as a `YamlMap`
  const factory YamlValue.yaml(YamlMap value) = YamlMapValue;

  /// {@macro yaml_value}
  ///
  /// represents the value as `null`
  const factory YamlValue.none() = YamlNone;

  /// parses the [value], typically a `String`, `YamlMap`, or `null`
  factory YamlValue.from(dynamic value) {
    if (value is String) {
      return YamlValue.string(value);
    } else if (value is YamlMap) {
      return YamlValue.yaml(value);
    } else if (value == null) {
      return const YamlValue.none();
    } else {
      throw UnsupportedError('Unsupported value type: ${value.runtimeType}');
    }
  }

  /// whether the value is a `String`
  bool isString() => this is YamlString;

  /// whether the value is a `YamlMap`
  bool isYaml() => this is YamlMapValue;

  /// whether the value is a `null`
  bool isNone() => this is YamlNone;

  /// converts to a `YamlMap`
  YamlMapValue asYaml() {
    if (!isYaml()) {
      throw ArgumentError('$this is not a $YamlMapValue');
    }

    return this as YamlMapValue;
  }

  /// converts to a `String`
  YamlString asString() {
    if (!isString()) {
      throw ArgumentError('$this is not a $YamlString');
    }

    return this as YamlString;
  }

  /// converts to a `null`
  YamlNone asNone() {
    if (!isNone()) {
      throw ArgumentError('$this is not a $YamlNone');
    }

    return this as YamlNone;
  }

  /// the value that is provided from the key in the yaml file
  final dynamic value;
}

class YamlString extends YamlValue {
  const YamlString(this.value) : super(value);

  @override
  final String value;
}

class YamlMapValue extends YamlValue {
  const YamlMapValue(this.value) : super(value);

  @override
  final YamlMap value;
}

class YamlNone extends YamlValue {
  const YamlNone() : super(null);

  @override
  Null get value => null;
}
