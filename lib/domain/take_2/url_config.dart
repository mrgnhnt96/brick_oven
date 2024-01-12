import 'package:brick_oven/domain/take_2/name_config.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'url_config.g.dart';

@JsonSerializable()
class UrlConfig extends Equatable {
  const UrlConfig({
    required this.name,
  });

  factory UrlConfig.fromJson(Map json) => _$UrlConfigFromJson(json);

  final NameConfig? name;

  Map<String, dynamic> toJson() => _$UrlConfigToJson(this);

  @override
  List<Object?> get props => _$props;
}
