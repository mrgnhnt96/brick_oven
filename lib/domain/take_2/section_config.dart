import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'section_config.g.dart';

@JsonSerializable()
class SectionConfig extends Equatable {
  const SectionConfig({
    required this.name,
    this.isInverted = false,
  });

  factory SectionConfig.fromJson(Map json) => _$SectionConfigFromJson(json);

  final String name;
  final bool isInverted;

  Map<String, dynamic> toJson() => _$SectionConfigToJson(this);

  @override
  List<Object?> get props => _$props;
}
