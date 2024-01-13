// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mason_brick_config.dart';

// **************************************************************************
// AutoequalGenerator
// **************************************************************************

extension _$MasonBrickConfigAutoequal on MasonBrickConfig {
  List<Object?> get _$props => [
        path,
        ignoreVars,
      ];
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MasonBrickConfig _$MasonBrickConfigFromJson(Map json) {
  $checkKeys(
    json,
    allowedKeys: const ['path', 'ignore_vars'],
  );
  return MasonBrickConfig(
    path: json['path'] as String,
    ignoreVars: (json['ignore_vars'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
  );
}

Map<String, dynamic> _$MasonBrickConfigToJson(MasonBrickConfig instance) =>
    <String, dynamic>{
      'path': instance.path,
      'ignore_vars': instance.ignoreVars,
    };
