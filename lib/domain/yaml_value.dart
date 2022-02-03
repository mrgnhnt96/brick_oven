// ignore_for_file: overridden_fields

import 'package:yaml/yaml.dart';

abstract class YamlValue {
  const YamlValue(this.value);
  const factory YamlValue.string(String value) = YamlString;
  const factory YamlValue.yaml(YamlMap value) = YamlMapValue;
  const factory YamlValue.none() = YamlNone;

  factory YamlValue.from(dynamic value) {
    switch (value.runtimeType) {
      case String:
        return YamlValue.string(value as String);
      case YamlMap:
        return YamlValue.yaml(value as YamlMap);
      default:
        return const YamlValue.none();
    }
  }

  bool isString() => this is YamlString;
  bool isYaml() => this is YamlMapValue;
  bool isNone() => this is YamlNone;

  YamlMapValue asYaml() => this as YamlMapValue;
  YamlString asString() => this as YamlString;
  YamlNone asNone() => this as YamlNone;

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
