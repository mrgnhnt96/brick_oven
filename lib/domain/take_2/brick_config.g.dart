// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brick_config.dart';

// **************************************************************************
// AutoequalGenerator
// **************************************************************************

extension _$BrickConfigAutoequal on BrickConfig {
  List<Object?> get _$props => [
        name,
        source,
        brickConfig,
        files,
        directories,
      ];
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrickConfig _$BrickConfigFromJson(Map json) {
  $checkKeys(
    json,
    allowedKeys: const ['name', 'source', 'brick_config', 'files', 'dirs'],
  );
  return BrickConfig(
    name: json['name'] as String,
    source: json['source'] as String,
    brickConfig: json['brick_config'] as String?,
    files: (json['files'] as Map?)?.map(
      (k, e) => MapEntry(k as String, FileConfig.fromJson(e as Map)),
    ),
    directories: (json['dirs'] as Map?)?.map(
      (k, e) => MapEntry(k as String, DirectoryConfig.fromJson(e as Map)),
    ),
  );
}

Map<String, dynamic> _$BrickConfigToJson(BrickConfig instance) {
  final val = <String, dynamic>{
    'name': instance.name,
    'source': instance.source,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('brick_config', instance.brickConfig);
  writeNotNull('files', instance.files?.map((k, e) => MapEntry(k, e.toJson())));
  writeNotNull(
      'dirs', instance.directories?.map((k, e) => MapEntry(k, e.toJson())));
  return val;
}
