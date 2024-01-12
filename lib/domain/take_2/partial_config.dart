import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'partial_config.g.dart';

@JsonSerializable()
class PartialConfig extends Equatable {
  const PartialConfig({
    required this.variables,
  });

  factory PartialConfig.fromJson(Map json) => _$PartialConfigFromJson(json);

  @JsonKey(name: 'vars')
  final Map<String, String>? variables;

  Map<String, dynamic> toJson() => _$PartialConfigToJson(this);

  @override
  List<Object?> get props => _$props;
}
