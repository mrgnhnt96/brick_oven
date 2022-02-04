import 'package:brick_oven/enums/mustache_format.dart';
import 'package:equatable/equatable.dart';
import 'package:yaml/yaml.dart';

class Variable extends Equatable {
  const Variable({
    required this.placeholder,
    required this.name,
    MustacheFormat? format,
    this.suffix,
    this.prefix,
  }) : format = format ?? MustacheFormat.camelCase;

  const Variable._fromYaml({
    required this.placeholder,
    required this.name,
    required this.suffix,
    required this.prefix,
    MustacheFormat? format,
  }) : format = format ?? MustacheFormat.camelCase;

  factory Variable.fromYaml(String name, YamlMap? yaml) {
    final map = yaml?.value ?? <String, dynamic>{};

    final formatString = map.remove('format') as String?;
    final format = MustacheFormat.values.retrieve(formatString);
    final placeholder = map.remove('placeholder') as String?;
    final suffix = map.remove('suffix') as String?;
    final prefix = map.remove('prefix') as String?;

    if (map.isNotEmpty) {
      throw ArgumentError('Unknown keys in variable: ${map.keys}');
    }

    return Variable._fromYaml(
      placeholder: placeholder ?? name,
      name: name,
      format: format,
      suffix: suffix,
      prefix: prefix,
    );
  }

  final String placeholder;
  final String name;
  final String? prefix;
  final String? suffix;
  final MustacheFormat format;

  String formatName(MustacheFormat format) {
    return format.toMustache('${prefix ?? ''}{{{$name}}}${suffix ?? ''}');
  }

  String get formattedName => formatName(format);

  @override
  List<Object?> get props => [
        placeholder,
        name,
        prefix,
        suffix,
        format,
      ];
}
