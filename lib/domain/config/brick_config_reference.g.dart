// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brick_config_reference.dart';

// **************************************************************************
// AutoequalGenerator
// **************************************************************************

extension _$BrickConfigReferenceAutoequal on BrickConfigReference {
  List<Object?> get _$props => [path];
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrickConfigReference _$BrickConfigReferenceFromJson(Map json) {
  $checkKeys(
    json,
    allowedKeys: const ['path'],
  );
  return BrickConfigReference(
    path: json['path'] as String,
  );
}

Map<String, dynamic> _$BrickConfigReferenceToJson(
        BrickConfigReference instance) =>
    <String, dynamic>{
      'path': instance.path,
    };
