// ignore_for_file: overridden_fields

import 'package:yaml/yaml.dart';

abstract class YamlValue {
  const YamlValue(this.value);
  const factory YamlValue.string(String value) = YamlString;
  const factory YamlValue.yaml(YamlMap value) = YamlMapValue;
  const factory YamlValue.none() = YamlNone;

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

  bool isString() => this is YamlString;
  bool isYaml() => this is YamlMapValue;
  bool isNone() => this is YamlNone;

  YamlMapValue asYaml() {
    if (!isYaml()) {
      throw ArgumentError('$this is not a $YamlMapValue');
    }

    return this as YamlMapValue;
  }

  YamlString asString() {
    if (!isString()) {
      throw ArgumentError('$this is not a $YamlString');
    }

    return this as YamlString;
  }

  YamlNone asNone() {
    if (!isNone()) {
      throw ArgumentError('$this is not a $YamlNone');
    }

    return this as YamlNone;
  }

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
