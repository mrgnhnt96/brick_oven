import 'package:brick_oven/domain/take_2/include_config.dart';
import 'package:brick_oven/domain/take_2/name_config.dart';
import 'package:brick_oven/domain/take_2/string_or_entry.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'file_config.g.dart';

@JsonSerializable()
class FileConfig extends Equatable {
  const FileConfig({
    required this.name,
    required this.variables,
    required this.include,
  });

  factory FileConfig.fromJson(Map json) => _$FileConfigFromJson(json);

  final StringOr<NameConfig>? name;
  @JsonKey(name: 'vars')
  final Map<String, String?>? variables;
  final IncludeConfig? include;

  Map<String, dynamic> toJson() => _$FileConfigToJson(this);

  @override
  List<Object?> get props => _$props;
}
