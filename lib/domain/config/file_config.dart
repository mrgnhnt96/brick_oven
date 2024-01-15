import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:brick_oven/domain/config/include_config.dart';
import 'package:brick_oven/domain/config/name_config.dart';
import 'package:brick_oven/domain/config/string_or_entry.dart';
import 'package:brick_oven/utils/vars_mixin.dart';

part 'file_config.g.dart';

@JsonSerializable()
class FileConfig extends Equatable with VarsMixin {
  const FileConfig({
    required this.nameConfig,
    required this.variableConfig,
    required this.includeConfig,
  });

  FileConfig.self(FileConfig? self)
      : this(
          nameConfig: self?.nameConfig,
          variableConfig: self?.variableConfig,
          includeConfig: self?.includeConfig,
        );

  FileConfig.forTarget(String path)
      : nameConfig = StringOr(string: path),
        variableConfig = null,
        includeConfig = null;

  factory FileConfig.fromJson(Map json) => _$FileConfigFromJson(json);

  @JsonKey(name: 'name')
  final StringOr<NameConfig>? nameConfig;
  @JsonKey(name: 'vars')
  final Map<String, String?>? variableConfig;
  @JsonKey(name: 'include')
  final IncludeConfig? includeConfig;

  @override
  List get variablesToProcess => [
        variableConfig,
        nameConfig?.string,
      ];

  @override
  List<Iterable<(String, String)>> get combine => [
        nameConfig?.object?.varsMap ?? {},
        includeConfig?.varsMap ?? {},
      ];

  Map<String, dynamic> toJson() => _$FileConfigToJson(this);

  @override
  List<Object?> get props => _$props;
}
