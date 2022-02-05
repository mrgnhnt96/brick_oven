import 'package:yaml/yaml.dart';

extension YamlMapX on YamlMap {
  Map<String, dynamic> get data {
    return Map<String, dynamic>.from(value);
  }
}
