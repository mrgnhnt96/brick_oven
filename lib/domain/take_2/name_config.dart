import 'package:brick_oven/domain/take_2/section_config.dart';
import 'package:brick_oven/domain/take_2/string_or_entry.dart';
import 'package:brick_oven/domain/take_2/utils/vars_mixin.dart';
import 'package:brick_oven/src/constants/constants.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:brick_oven/enums/mustache_tag.dart';

part 'name_config.g.dart';

@JsonSerializable()
class NameConfig extends Equatable with VarsMixin {
  NameConfig({
    required this.renameWith,
    this.tag,
    this.prefix = '',
    this.suffix = '',
    this.section,
    this.braces = Constants.kDefaultBraces,
  })  : assert(
          renameWith == null || renameWith.isNotEmpty,
          'renameWith cannot be empty',
        ),
        assert(
          braces == 2 || braces == 3,
          'braces must be 2 or 3',
        ),
        assert(
          tag == null || tag.isFormat,
          'format must be a format tag',
        );

  NameConfig.self(NameConfig config)
      : this(
          renameWith: config.renameWith,
          tag: config.tag,
          prefix: config.prefix,
          suffix: config.suffix,
          section: config.section,
          braces: config.braces,
        );

  factory NameConfig.fromJson(Map json) => _$NameConfigFromJson(json);

  final String? renameWith;
  @JsonKey(name: 'format')
  final MustacheTag? tag;
  final String prefix;
  final String suffix;
  final StringOr<SectionConfig>? section;
  final int braces;

  @override
  List get variablesToProcess => [
        renameWith,
        section?.string,
      ];

  @override
  List<Iterable<(String, String)>> get combine => [
        section?.object?.varsMap ?? {},
      ];

  Map<String, dynamic> toJson() => _$NameConfigToJson(this);

  @override
  List<Object?> get props => _$props;
}
