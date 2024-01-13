import 'package:brick_oven/domain/config/brick_config.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:brick_oven/domain/config/brick_config_entry.dart';

part 'brick_oven_config.g.dart';

@JsonSerializable()
class BrickOvenConfig extends Equatable {
  const BrickOvenConfig({
    required this.bricks,
    required this.configPath,
  });

  factory BrickOvenConfig.fromJson(
    Map json, {
    required String configPath,
  }) {
    json['config_path'] = configPath;

    return _$BrickOvenConfigFromJson(json);
  }

  final Map<String, BrickConfigEntry>? bricks;
  final String configPath;

  Map<String, BrickConfig> resolveBricks() =>
      bricks?.map(
        (k, v) => MapEntry(
          k,
          v.resolve(fromPath: configPath),
        ),
      ) ??
      {};

  Map<String, dynamic> toJson() => _$BrickOvenConfigToJson(this);

  @override
  List<Object?> get props => _$props;
}

List<Map> _readBrick(Map json, String key) {
  if (json.containsKey(key)) {
    return List.from(json[key] as List);
  } else {
    return [];
  }
}
