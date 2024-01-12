import 'package:brick_oven/domain/take_2/brick_config_entry.dart';
import 'package:brick_oven/domain/take_2/directory_config.dart';
import 'package:brick_oven/domain/take_2/file_config.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'brick_config.g.dart';

@JsonSerializable()
class BrickConfig extends BrickConfigEntry with EquatableMixin {
  const BrickConfig({
    required this.name,
    required this.source,
    required this.brickConfig,
    required this.files,
    required this.directories,
  });

  factory BrickConfig.fromJson(
    Map json, {
    String? name,
  }) {
    json['name'] ??= name;

    return _$BrickConfigFromJson(json);
  }

  final String name;
  final String source;
  final String? brickConfig;
  final Map<String, FileConfig>? files;
  @JsonKey(name: 'dirs')
  final Map<String, DirectoryConfig>? directories;

  @override
  Map<String, dynamic> toJson() => _$BrickConfigToJson(this);

  @override
  List<Object?> get props => _$props;
}
