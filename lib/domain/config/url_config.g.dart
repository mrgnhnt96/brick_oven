// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'url_config.dart';

// **************************************************************************
// AutoequalGenerator
// **************************************************************************

extension _$UrlConfigAutoequal on UrlConfig {
  List<Object?> get _$props => [
        nameConfig,
        includeConfig,
      ];
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UrlConfig _$UrlConfigFromJson(Map json) {
  $checkKeys(
    json,
    allowedKeys: const ['name', 'include'],
  );
  return UrlConfig(
    nameConfig:
        json['name'] == null ? null : NameConfig.fromJson(json['name'] as Map),
    includeConfig: json['include'] == null
        ? null
        : IncludeConfig.fromJson(json['include'] as Map),
  );
}

Map<String, dynamic> _$UrlConfigToJson(UrlConfig instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.nameConfig?.toJson());
  writeNotNull('include', instance.includeConfig?.toJson());
  return val;
}
