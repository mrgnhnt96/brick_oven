// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brick_oven_config.dart';

// **************************************************************************
// AutoequalGenerator
// **************************************************************************

extension _$BrickOvenConfigAutoequal on BrickOvenConfig {
  List<Object?> get _$props => [
        bricks,
        configPath,
      ];
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrickOvenConfig _$BrickOvenConfigFromJson(Map json) {
  $checkKeys(
    json,
    allowedKeys: const ['bricks', 'config_path'],
  );
  return BrickOvenConfig(
    bricks: BrickConfigEntry.fromJsonList(
        _readBrick(json, 'bricks') as List<Map<dynamic, dynamic>>),
    configPath: json['config_path'] as String,
  );
}

Map<String, dynamic> _$BrickOvenConfigToJson(BrickOvenConfig instance) =>
    <String, dynamic>{
      'bricks': instance.bricks.map((e) => e.toJson()).toList(),
      'config_path': instance.configPath,
    };
