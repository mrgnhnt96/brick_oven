// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directory_config.dart';

// **************************************************************************
// AutoequalGenerator
// **************************************************************************

extension _$DirectoryConfigAutoequal on DirectoryConfig {
  List<Object?> get _$props => [
        name,
        include,
      ];
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DirectoryConfig _$DirectoryConfigFromJson(Map json) {
  $checkKeys(
    json,
    allowedKeys: const ['name', 'include'],
  );
  return DirectoryConfig(
    name:
        json['name'] == null ? null : NameConfig.fromJson(json['name'] as Map),
    include: json['include'] == null
        ? null
        : IncludeConfig.fromJson(json['include'] as Map),
  );
}

Map<String, dynamic> _$DirectoryConfigToJson(DirectoryConfig instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name?.toJson());
  writeNotNull('include', instance.include?.toJson());
  return val;
}
