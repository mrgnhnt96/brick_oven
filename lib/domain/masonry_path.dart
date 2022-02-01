import 'package:masonry/enums/mason_format.dart';
import 'package:yaml/yaml.dart';

class MasonryPath {
  const MasonryPath({
    required this.placeholder,
    required this.name,
  });

  factory MasonryPath.fromYaml(String part, YamlMap yaml) {
    final name = yaml['name'] as String;

    return MasonryPath(
      placeholder: part,
      name: name,
    );
  }

  final String placeholder;
  final String name;

  String apply(String path) {
    if (!path.contains(placeholder)) {
      return path;
    }

    final pattern = RegExp(r'\b' + placeholder + r'\b');

    return path.replaceAll(
      pattern,
      MasonFormat.snakeCase.toMustache('{{{$name}}}'),
    );
  }
}
