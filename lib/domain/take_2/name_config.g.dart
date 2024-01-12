// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'name_config.dart';

// **************************************************************************
// AutoequalGenerator
// **************************************************************************

extension _$NameConfigAutoequal on NameConfig {
  List<Object?> get _$props => [
        renameWith,
        format,
        prefix,
        suffix,
        section,
        braces,
      ];
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NameConfig _$NameConfigFromJson(Map json) {
  $checkKeys(
    json,
    allowedKeys: const [
      'rename_with',
      'format',
      'prefix',
      'suffix',
      'section',
      'braces'
    ],
  );
  return NameConfig(
    renameWith: json['rename_with'] as String,
    format: $enumDecodeNullable(_$MustacheTagEnumMap, json['format']),
    prefix: json['prefix'] as String? ?? '',
    suffix: json['suffix'] as String? ?? '',
    section: json['section'] == null
        ? null
        : SectionConfig.fromJson(json['section'] as Map),
    braces: json['braces'] as int? ?? 2,
  );
}

Map<String, dynamic> _$NameConfigToJson(NameConfig instance) {
  final val = <String, dynamic>{
    'rename_with': instance.renameWith,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('format', _$MustacheTagEnumMap[instance.format]);
  val['prefix'] = instance.prefix;
  val['suffix'] = instance.suffix;
  writeNotNull('section', instance.section?.toJson());
  val['braces'] = instance.braces;
  return val;
}

const _$MustacheTagEnumMap = {
  MustacheTag.camelCase: 'camelCase',
  MustacheTag.constantCase: 'constantCase',
  MustacheTag.dotCase: 'dotCase',
  MustacheTag.headerCase: 'headerCase',
  MustacheTag.lowerCase: 'lowerCase',
  MustacheTag.mustacheCase: 'mustacheCase',
  MustacheTag.pascalCase: 'pascalCase',
  MustacheTag.paramCase: 'paramCase',
  MustacheTag.pathCase: 'pathCase',
  MustacheTag.sentenceCase: 'sentenceCase',
  MustacheTag.snakeCase: 'snakeCase',
  MustacheTag.titleCase: 'titleCase',
  MustacheTag.upperCase: 'upperCase',
  MustacheTag.ifNot: 'ifNot',
  MustacheTag.if_: 'if_',
  MustacheTag.endIf: 'endIf',
};
