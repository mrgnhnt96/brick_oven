import 'package:brick_oven/domain/take_2/brick_config_entry.dart';
import 'package:brick_oven/domain/take_2/directory_config.dart';
import 'package:brick_oven/domain/take_2/file_config.dart';
import 'package:brick_oven/domain/take_2/mason_brick_config.dart';
import 'package:brick_oven/domain/take_2/partial_config.dart';
import 'package:brick_oven/domain/take_2/string_or_entry.dart';
import 'package:brick_oven/domain/take_2/url_config.dart';
import 'package:brick_oven/domain/take_2/utils/vars_mixin.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'brick_config.g.dart';

@JsonSerializable()
class BrickConfig extends BrickConfigEntry with EquatableMixin, VarsMixin {
  const BrickConfig({
    required this.sourcePath,
    required this.masonBrickConfig,
    required this.fileConfigs,
    required this.directoryConfigs,
    required this.urlConfigs,
    required this.partialConfigs,
    required this.exclude,
    required this.configPath,
  });

  BrickConfig.self(BrickConfig self)
      : this(
          sourcePath: self.sourcePath,
          masonBrickConfig: self.masonBrickConfig,
          fileConfigs: self.fileConfigs,
          directoryConfigs: self.directoryConfigs,
          urlConfigs: self.urlConfigs,
          partialConfigs: self.partialConfigs,
          exclude: self.exclude,
          configPath: self.configPath,
        );

  factory BrickConfig.fromJson(
    Map json, {
    required String? configPath,
  }) {
    final sanitized = <dynamic, dynamic>{};

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

    sanitized['config_path'] = configPath;

    return _$BrickConfigFromJson(sanitized);
  }

  @JsonKey(name: 'source')
  final String sourcePath;
  @JsonKey(name: 'brick_config')
  final StringOr<MasonBrickConfig>? masonBrickConfig;
  @JsonKey(name: 'files')
  final Map<String, FileConfig>? fileConfigs;
  @JsonKey(name: 'dirs')
  final Map<String, DirectoryConfig>? directoryConfigs;
  @JsonKey(name: 'urls')
  final Map<String, UrlConfig>? urlConfigs;
  @JsonKey(name: 'partials')
  final Map<String, PartialConfig?>? partialConfigs;
  final List<String>? exclude;
  final String? configPath;

  @override
  List<Iterable<(String, String)>> get combine => [
        ...?fileConfigs?.values.map((e) => e.varsMap),
        ...?directoryConfigs?.values.map((e) => e.varsMap),
        ...?urlConfigs?.values.map((e) => e.varsMap),
        ...?partialConfigs?.values.map((e) => e?.varsMap ?? []),
      ];

  @override
  @override
  Map<String, dynamic> toJson() => _$BrickConfigToJson(this);

  @override
  List<Object?> get props => _$props;
}
