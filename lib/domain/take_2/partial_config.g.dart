// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partial_config.dart';

// **************************************************************************
// AutoequalGenerator
// **************************************************************************

extension _$PartialConfigAutoequal on PartialConfig {
  List<Object?> get _$props => [variables];
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PartialConfig _$PartialConfigFromJson(Map json) {
  $checkKeys(
    json,
    allowedKeys: const ['vars'],
  );
  return PartialConfig(
    variables: (json['vars'] as Map?)?.map(
      (k, e) => MapEntry(k as String, e as String),
    ),
  );
}

Map<String, dynamic> _$PartialConfigToJson(PartialConfig instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('vars', instance.variables);
  return val;
}
