// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brick_config_reference.dart';

// **************************************************************************
// AutoequalGenerator
// **************************************************************************

extension _$BrickConfigReferenceAutoequal on BrickConfigReference {
  List<Object?> get _$props => [
        name,
        path,
      ];
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrickConfigReference _$BrickConfigReferenceFromJson(Map json) {
  $checkKeys(
    json,
    allowedKeys: const ['name', 'path'],
  );
  return BrickConfigReference(
    name: json['name'] as String,
    path: json['path'] as String,
  );
}

Map<String, dynamic> _$BrickConfigReferenceToJson(
        BrickConfigReference instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
    };
