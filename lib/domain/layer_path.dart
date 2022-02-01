import 'package:brick_layer/enums/mustache_format.dart';
import 'package:yaml/yaml.dart';

class LayerPath {
  const LayerPath({
    required this.placeholder,
    required this.name,
  });

  factory LayerPath.fromYaml(String part, YamlMap yaml) {
    final name = yaml['name'] as String;

    return LayerPath(
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
      MustacheFormat.snakeCase.toMustache('{{{$name}}}'),
    );
  }
}
