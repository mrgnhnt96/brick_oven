import 'package:brick_oven/domain/config/include_config.dart';
import 'package:brick_oven/domain/config/name_config.dart';
import 'package:brick_oven/utils/vars_mixin.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'url_config.g.dart';

@JsonSerializable()
class UrlConfig extends Equatable with VarsMixin {
  const UrlConfig({
    required this.nameConfig,
    required this.includeConfig,
  });

  UrlConfig.self(UrlConfig config)
      : this(
          nameConfig: config.nameConfig,
          includeConfig: config.includeConfig,
        );

  factory UrlConfig.fromJson(Map json) => _$UrlConfigFromJson(json);

  @JsonKey(name: 'name')
  final NameConfig? nameConfig;
  @JsonKey(name: 'include')
  final IncludeConfig? includeConfig;

  Map<String, dynamic> toJson() => _$UrlConfigToJson(this);

  @override
  List<Object?> get props => _$props;

  @override
  List<Iterable<(String, String)>> get combine => [
        nameConfig?.varsMap ?? {},
        includeConfig?.varsMap ?? {},
      ];
}
