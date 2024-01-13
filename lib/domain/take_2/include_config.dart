import 'package:brick_oven/domain/take_2/utils/vars_mixin.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'include_config.g.dart';

@JsonSerializable()
class IncludeConfig extends Equatable with VarsMixin {
  const IncludeConfig({
    this.$if,
    this.ifNot,
  }) : assert(
          $if != null || ifNot != null,
          'IncludeConfig must have either an `if` or `ifNot`',
        );

  IncludeConfig.self(IncludeConfig config)
      : this(
          $if: config.$if,
          ifNot: config.ifNot,
        );

  factory IncludeConfig.fromJson(Map json) => _$IncludeConfigFromJson(json);

  @JsonKey(name: 'if')
  final String? $if;
  final String? ifNot;

  bool get isIf => $if != null;

  @override
  List get variablesToProcess => [$if, ifNot];

  Map<String, dynamic> toJson() => _$IncludeConfigToJson(this);

  @override
  List<Object?> get props => _$props;
}
