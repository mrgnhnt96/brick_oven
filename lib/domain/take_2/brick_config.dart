import 'package:brick_oven/domain/take_2/brick_config_entry.dart';
import 'package:brick_oven/domain/take_2/directory_config.dart';
import 'package:brick_oven/domain/take_2/file_config.dart';
import 'package:brick_oven/domain/take_2/partial_config.dart';
import 'package:brick_oven/domain/take_2/url_config.dart';
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
    required this.urls,
    required this.partials,
    required this.exclude,
  });

  factory BrickConfig.fromJson(
    Map json, {
    String? name,
  }) {
    final Map sanitized = {};

    if (json.keys.length == 1) {
      final first = json.entries.first;
      if (first.value is! Map) {
        throw Exception('value must be a Map');
      }

      sanitized.addAll(Map.from(first.value as Map));
      sanitized['name'] ??= first.key;
    } else {
      sanitized.addAll(json);
    }

    sanitized['name'] ??= name;

    return _$BrickConfigFromJson(sanitized);
  }

  final String name;
  final String source;
  final String? brickConfig;
  final Map<String, FileConfig>? files;
  @JsonKey(name: 'dirs')
  final Map<String, DirectoryConfig>? directories;
  final Map<String, UrlConfig>? urls;
  final Map<String, PartialConfig>? partials;
  final List<String>? exclude;

  @override
  Map<String, dynamic> toJson() => _$BrickConfigToJson(this);

  @override
  List<Object?> get props => _$props;
}
