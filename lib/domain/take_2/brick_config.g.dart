// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brick_config.dart';

// **************************************************************************
// AutoequalGenerator
// **************************************************************************

extension _$BrickConfigAutoequal on BrickConfig {
  List<Object?> get _$props => [
        sourcePath,
        masonBrickConfig,
        fileConfigs,
        directoryConfigs,
        urlConfigs,
        partialConfigs,
        exclude,
        configPath,
      ];
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrickConfig _$BrickConfigFromJson(Map json) {
  $checkKeys(
    json,
    allowedKeys: const [
      'source',
      'brick_config',
      'files',
      'dirs',
      'urls',
      'partials',
      'exclude',
      'config_path'
    ],
  );
  return BrickConfig(
    sourcePath: json['source'] as String,
    masonBrickConfig: json['brick_config'] == null
        ? null
        : StringOr<MasonBrickConfig>.fromJson(json['brick_config'],
            (value) => MasonBrickConfig.fromJson(value as Map)),
    fileConfigs: (json['files'] as Map?)?.map(
      (k, e) => MapEntry(k as String, FileConfig.fromJson(e as Map)),
    ),
    directoryConfigs: (json['dirs'] as Map?)?.map(
      (k, e) => MapEntry(k as String, DirectoryConfig.fromJson(e as Map)),
    ),
    urlConfigs: (json['urls'] as Map?)?.map(
      (k, e) => MapEntry(k as String, UrlConfig.fromJson(e as Map)),
    ),
    partialConfigs: (json['partials'] as Map?)?.map(
      (k, e) => MapEntry(
          k as String, e == null ? null : PartialConfig.fromJson(e as Map)),
    ),
    exclude:
        (json['exclude'] as List<dynamic>?)?.map((e) => e as String).toList(),
    configPath: json['config_path'] as String?,
  );
}

Map<String, dynamic> _$BrickConfigToJson(BrickConfig instance) {
  final val = <String, dynamic>{
    'source': instance.sourcePath,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'brick_config',
      instance.masonBrickConfig?.toJson(
        (value) => value.toJson(),
      ));
  writeNotNull(
      'files', instance.fileConfigs?.map((k, e) => MapEntry(k, e.toJson())));
  writeNotNull('dirs',
      instance.directoryConfigs?.map((k, e) => MapEntry(k, e.toJson())));
  writeNotNull(
      'urls', instance.urlConfigs?.map((k, e) => MapEntry(k, e.toJson())));
  writeNotNull('partials',
      instance.partialConfigs?.map((k, e) => MapEntry(k, e?.toJson())));
  writeNotNull('exclude', instance.exclude);
  writeNotNull('config_path', instance.configPath);
  return val;
}
