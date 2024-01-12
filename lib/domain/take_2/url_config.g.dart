// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'url_config.dart';

// **************************************************************************
// AutoequalGenerator
// **************************************************************************

extension _$UrlConfigAutoequal on UrlConfig {
  List<Object?> get _$props => [name];
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UrlConfig _$UrlConfigFromJson(Map json) {
  $checkKeys(
    json,
    allowedKeys: const ['name'],
  );
  return UrlConfig(
    name:
        json['name'] == null ? null : NameConfig.fromJson(json['name'] as Map),
  );
}

Map<String, dynamic> _$UrlConfigToJson(UrlConfig instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name?.toJson());
  return val;
}
