import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'include_config.g.dart';

@JsonSerializable()
class IncludeConfig extends Equatable {
  const IncludeConfig({
    this.$if,
    this.ifNot,
  }) : assert(
          $if != null || ifNot != null,
          'IncludeConfig must have either an `if` or `ifNot`',
        );

  factory IncludeConfig.fromJson(Map json) => _$IncludeConfigFromJson(json);

  @JsonKey(name: 'if')
  final String? $if;
  final String? ifNot;

  Map<String, dynamic> toJson() => _$IncludeConfigToJson(this);

  @override
  List<Object?> get props => _$props;
}
