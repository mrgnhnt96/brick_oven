import 'package:brick_oven/utils/vars_mixin.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'partial_config.g.dart';

@JsonSerializable()
class PartialConfig extends Equatable with VarsMixin {
  const PartialConfig({
    required this.variableConfig,
  });

  PartialConfig.self(PartialConfig? config)
      : this(
          variableConfig: config?.variableConfig ?? {},
        );

  factory PartialConfig.fromJson(Map json) => _$PartialConfigFromJson(json);

  @JsonKey(name: 'vars')
  final Map<String, String?>? variableConfig;

  Map<String, dynamic> toJson() => _$PartialConfigToJson(this);

  @override
  List<Object?> get props => _$props;

  @override
  List get variablesToProcess => [
        variableConfig,
      ];
}
