// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'include_config.dart';

// **************************************************************************
// AutoequalGenerator
// **************************************************************************

extension _$IncludeConfigAutoequal on IncludeConfig {
  List<Object?> get _$props => [
        $if,
        ifNot,
      ];
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IncludeConfig _$IncludeConfigFromJson(Map json) {
  $checkKeys(
    json,
    allowedKeys: const ['if', 'if_not'],
  );
  return IncludeConfig(
    $if: json['if'] as String?,
    ifNot: json['if_not'] as String?,
  );
}

Map<String, dynamic> _$IncludeConfigToJson(IncludeConfig instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('if', instance.$if);
  writeNotNull('if_not', instance.ifNot);
  return val;
}
