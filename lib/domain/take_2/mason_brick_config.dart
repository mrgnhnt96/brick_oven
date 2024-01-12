import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mason_brick_config.g.dart';

@JsonSerializable()
class MasonBrickConfig extends Equatable {
  const MasonBrickConfig({
    required this.path,
    required this.ignoreVars,
  });

  factory MasonBrickConfig.fromJson(Map json) =>
      _$MasonBrickConfigFromJson(json);

  final String path;
  final List<String> ignoreVars;

  Map<String, dynamic> toJson() => _$MasonBrickConfigToJson(this);

  @override
  List<Object?> get props => _$props;
}
