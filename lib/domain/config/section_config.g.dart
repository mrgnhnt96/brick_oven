// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'section_config.dart';

// **************************************************************************
// AutoequalGenerator
// **************************************************************************

extension _$SectionConfigAutoequal on SectionConfig {
  List<Object?> get _$props => [
        name,
        isInverted,
      ];
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SectionConfig _$SectionConfigFromJson(Map json) {
  $checkKeys(
    json,
    allowedKeys: const ['name', 'is_inverted'],
  );
  return SectionConfig(
    name: json['name'] as String,
    isInverted: json['is_inverted'] as bool? ?? false,
  );
}

Map<String, dynamic> _$SectionConfigToJson(SectionConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'is_inverted': instance.isInverted,
    };
