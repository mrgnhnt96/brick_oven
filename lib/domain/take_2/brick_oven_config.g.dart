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
    bricks: (json['bricks'] as Map).map(
      (k, e) => MapEntry(k as String, BrickConfigEntry.fromJson(e as Map)),
    ),
    configPath: json['config_path'] as String,
  );
}

Map<String, dynamic> _$BrickOvenConfigToJson(BrickOvenConfig instance) =>
    <String, dynamic>{
      'bricks': instance.bricks.map((k, e) => MapEntry(k, e.toJson())),
      'config_path': instance.configPath,
    };
