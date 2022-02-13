import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

/// the extension for [YamlMap]

extension YamlMapX on YamlMap {
  /// returns a modifiable Map of the[value]
  Map<String, dynamic> get data {
    return Map<String, dynamic>.from(value);
  }
}

/// the extension for [Logger]
extension LoggerX on Logger {
  /// writes `Cooking...`
  void cooking() {
    info(cyan.wrap('\nCooking...'));
  }

  /// writes `Watching local files...`
  void watching() {
    info(lightYellow.wrap('\nWatching local files...'));
  }
}
