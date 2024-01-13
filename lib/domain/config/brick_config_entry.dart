import 'package:brick_oven/domain/config/brick_config.dart';
import 'package:brick_oven/domain/config/brick_config_reference.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:brick_oven/utils/yaml_to_json.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';

abstract mixin class BrickConfigEntry {
  const BrickConfigEntry();

  factory BrickConfigEntry.fromJson(Map json) {
    try {
      return BrickConfigReference.fromJson(json);
    } catch (_) {
      // do nothing
    }

    try {
      return BrickConfig.fromJson(json, configPath: null);
    } catch (err) {
      di<Logger>().err('Failed to parse brick config');
      throw const BrickConfigException(reason: 'Failed to parse brick config');
    }
  }

  Map<String, dynamic> toJson();

  bool get isReference => this is BrickConfigReference;
  bool get isBrick => this is BrickConfig;

  BrickConfigReference get reference => this as BrickConfigReference;
  BrickConfig get brick => this as BrickConfig;

  BrickConfig resolve({required String fromPath}) {
    if (isReference) {
      var path = reference.path;
      if (reference.isRelative) {
        path = join(dirname(fromPath), path);
      }

      final json = YamlToJson.fromPath(path);

      return BrickConfig.fromJson(
        json,
        configPath: path,
      );
    }

    return brick;
  }
}
