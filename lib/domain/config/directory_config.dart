import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:brick_oven/domain/config/include_config.dart';
import 'package:brick_oven/domain/config/name_config.dart';
import 'package:brick_oven/utils/vars_mixin.dart';

part 'directory_config.g.dart';

@JsonSerializable()
class DirectoryConfig extends Equatable with VarsMixin {
  const DirectoryConfig({
    required this.nameConfig,
    required this.includeConfig,
  });

  DirectoryConfig.self(DirectoryConfig config)
      : this(
          nameConfig: config.nameConfig,
          includeConfig: config.includeConfig,
        );

  factory DirectoryConfig.fromJson(Map json) => _$DirectoryConfigFromJson(json);

  @JsonKey(name: 'name')
  final NameConfig? nameConfig;
  @JsonKey(name: 'include')
  final IncludeConfig? includeConfig;

  Map<String, dynamic> toJson() => _$DirectoryConfigToJson(this);

  @override
  List<Object?> get props => _$props;

  @override
  List<Iterable<(String, String)>> get combine => [
        nameConfig?.varsMap ?? {},
        includeConfig?.varsMap ?? {},
      ];
}
