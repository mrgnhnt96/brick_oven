import 'package:brick_oven/domain/take_2/include_config.dart';
import 'package:brick_oven/domain/take_2/name_config.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'directory_config.g.dart';

@JsonSerializable()
class DirectoryConfig extends Equatable {
  const DirectoryConfig({
    required this.name,
    required this.include,
  });

  factory DirectoryConfig.fromJson(Map json) => _$DirectoryConfigFromJson(json);

  final NameConfig? name;
  final IncludeConfig? include;

  Map<String, dynamic> toJson() => _$DirectoryConfigToJson(this);

  @override
  List<Object?> get props => _$props;
}
