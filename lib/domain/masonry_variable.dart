import 'package:masonry/enums/mason_format.dart';
import 'package:yaml/yaml.dart';

class MasonryVariable {
  const MasonryVariable({
    required this.placeholder,
    required this.name,
    required this.format,
  })  : _suffix = null,
        _prefix = null;

  const MasonryVariable._fromYaml({
    required this.placeholder,
    required this.name,
    required String? suffix,
    required String? prefix,
    required this.format,
  })  : _suffix = suffix,
        _prefix = prefix;

  factory MasonryVariable.fromYaml(String placeholder, YamlMap yaml) {
    final format = MasonFormat.values.retrieve(yaml.value['format'] as String?);

    final name = yaml.value['name'] as String;
    final suffix = yaml.value['suffix'] as String?;
    final prefix = yaml.value['prefix'] as String?;

    return MasonryVariable._fromYaml(
      placeholder: placeholder,
      name: name,
      format: format ?? MasonFormat.camelCase,
      suffix: suffix,
      prefix: prefix,
    );
  }

  final String placeholder;
  final String name;
  final String? _prefix;
  final String? _suffix;
  final MasonFormat format;

  String get prefix => _prefix ?? '';
  String get suffix => _suffix ?? '';

  String formatName(MasonFormat format) {
    return format.toMustache('$prefix{{{$name}}}$suffix');
  }

  String get formattedName => formatName(format);
}
