// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_config.dart';

// **************************************************************************
// AutoequalGenerator
// **************************************************************************

extension _$FileConfigAutoequal on FileConfig {
  List<Object?> get _$props => [
        name,
        variables,
        include,
      ];
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileConfig _$FileConfigFromJson(Map json) {
  $checkKeys(
    json,
    allowedKeys: const ['name', 'vars', 'include'],
  );
  return FileConfig(
    name: json['name'] == null
        ? null
        : StringOr<NameConfig>.fromJson(
            json['name'], (value) => NameConfig.fromJson(value as Map)),
    variables: (json['vars'] as Map?)?.map(
      (k, e) => MapEntry(k as String, e as String?),
    ),
    include: json['include'] == null
        ? null
        : IncludeConfig.fromJson(json['include'] as Map),
  );
}

Map<String, dynamic> _$FileConfigToJson(FileConfig instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'name',
      instance.name?.toJson(
        (value) => value.toJson(),
      ));
  writeNotNull('vars', instance.variables);
  writeNotNull('include', instance.include?.toJson());
  return val;
}
