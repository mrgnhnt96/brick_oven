import 'package:brick_oven/domain/take_2/section_config.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:brick_oven/enums/mustache_tag.dart';

part 'name_config.g.dart';

@JsonSerializable()
class NameConfig extends Equatable {
  NameConfig({
    required this.renameWith,
    this.format,
    this.prefix = '',
    this.suffix = '',
    this.section,
    this.braces = 2,
  })  : assert(
          renameWith.isNotEmpty,
          'renameWith cannot be empty',
        ),
        assert(
          braces == 2 || braces == 3,
          'braces must be 2 or 3',
        ),
        assert(
          format == null || format.isFormat,
          'format must be a format tag',
        );

  factory NameConfig.fromJson(Map json) => _$NameConfigFromJson(json);

  final String renameWith;
  final MustacheTag? format;
  final String prefix;
  final String suffix;
  final SectionConfig? section;
  final int braces;

  Map<String, dynamic> toJson() => _$NameConfigToJson(this);

  @override
  List<Object?> get props => _$props;
}
