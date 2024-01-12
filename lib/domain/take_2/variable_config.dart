import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'variable_config.g.dart';

@JsonSerializable()
class VariableConfig extends Equatable {
  const VariableConfig();

  factory VariableConfig.fromJson(Map json) => _$VariableConfigFromJson(json);

  Map<String, dynamic> toJson() => _$VariableConfigToJson(this);

  @override
  List<Object?> get props => _$props;
}
