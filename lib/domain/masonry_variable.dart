import 'package:masonry/enums/mason_format.dart';
import 'package:masonry/enums/mason_type.dart';
import 'package:yaml/yaml.dart';

class MasonryVariable {
  const MasonryVariable({
    required this.placeholder,
    required String name,
    required this.format,
    required this.type,
  })  : _name = name,
        _suffix = null,
        _prefix = null;

  const MasonryVariable._fromYaml({
    required this.placeholder,
    required String name,
    required String? suffix,
    required String? prefix,
    required this.format,
    required this.type,
  })  : _name = name,
        _suffix = suffix,
        _prefix = prefix;

  factory MasonryVariable.fromYaml(String placeholder, YamlMap yaml) {
    final format = MasonFormat.values.retrieve(yaml.value['format'] as String?);
    final type = MasonType.values.retrieve(yaml.value['type'] as String?);

    final name = yaml.value['name'] as String;
    final suffix = yaml.value['suffix'] as String?;
    final prefix = yaml.value['prefix'] as String?;

    return MasonryVariable._fromYaml(
      placeholder: placeholder,
      name: name,
      format: format ?? MasonFormat.camelCase,
      suffix: suffix,
      prefix: prefix,
      type: type ?? MasonType.string,
    );
  }

  final String placeholder;
  final String _name;
  final String? _prefix;
  final String? _suffix;
  final MasonFormat format;
  final MasonType type;

  String get name {
    final prefix = _prefix ?? '';
    final suffix = _suffix ?? '';

    return '$prefix${format.toMustache(_name)}$suffix';
  }
}
