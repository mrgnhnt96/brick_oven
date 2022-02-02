import 'package:brick_oven/enums/mustache_format.dart';
import 'package:yaml/yaml.dart';

class Variable {
  const Variable({
    required this.placeholder,
    required this.name,
    MustacheFormat? format,
  })  : _suffix = null,
        format = format ?? MustacheFormat.camelCase,
        _prefix = null;

  const Variable._fromYaml({
    required this.placeholder,
    required this.name,
    required String? suffix,
    required String? prefix,
    MustacheFormat? format,
  })  : _suffix = suffix,
        format = format ?? MustacheFormat.camelCase,
        _prefix = prefix;

  factory Variable.fromYaml(String name, YamlMap yaml) {
    final map = yaml.value;

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
