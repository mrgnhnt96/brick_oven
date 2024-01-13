import 'package:brick_oven/domain/config/brick_config_entry.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'brick_config_reference.g.dart';

@JsonSerializable()
class BrickConfigReference extends BrickConfigEntry with EquatableMixin {
  const BrickConfigReference({
    required this.path,
  });

  factory BrickConfigReference.fromJson(Map json) =>
      _$BrickConfigReferenceFromJson(json);

  final String path;

  bool get isRelative => !path.startsWith('/');

  @override
  Map<String, dynamic> toJson() => _$BrickConfigReferenceToJson(this);

  @override
  List<Object?> get props => _$props;
}
