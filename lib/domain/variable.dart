import 'package:brick_layer/enums/mustache_format.dart';
import 'package:yaml/yaml.dart';

class Variable {
  const Variable({
    required this.placeholder,
    required this.name,
    required this.format,
  })  : _suffix = null,
        _prefix = null;

  const Variable._fromYaml({
    required this.placeholder,
    required this.name,
    required String? suffix,
    required String? prefix,
    required this.format,
  })  : _suffix = suffix,
        _prefix = prefix;

  factory Variable.fromYaml(String placeholder, YamlMap yaml) {
    final format =
        MustacheFormat.values.retrieve(yaml.value['format'] as String?);

    final name = yaml.value['name'] as String;
    final suffix = yaml.value['suffix'] as String?;
    final prefix = yaml.value['prefix'] as String?;

    return Variable._fromYaml(
      placeholder: placeholder,
      name: name,
      format: format ?? MustacheFormat.camelCase,
      suffix: suffix,
      prefix: prefix,
    );
  }

  final String placeholder;
  final String name;
  final String? _prefix;
  final String? _suffix;
  final MustacheFormat format;

  String get prefix => _prefix ?? '';
  String get suffix => _suffix ?? '';

  String formatName(MustacheFormat format) {
    return format.toMustache('$prefix{{{$name}}}$suffix');
  }

  String get formattedName => formatName(format);
}
