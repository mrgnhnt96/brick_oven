import 'package:brick_layer/enums/mustache_format.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class BrickPath {
  BrickPath({
    required this.name,
    required this.path,
  }) : placeholder = path.substring(path.lastIndexOf(separator) + 1).replaceAll(
              RegExp(r'^\' + separator + r'|\' + separator + r'$'),
              '',
            );

  factory BrickPath.fromYaml(String path, YamlMap yaml) {
    final name = yaml['name'] as String;

    return BrickPath(path: path, name: name);
  }

  final String placeholder;
  final String name;
  final String path;

  List<String> get parts => path.split(separator);

  String apply(
    String path, {
    required String originalPath,
  }) {
    if (!this.path.contains(separator)) {
      return path;
    } else if (!originalPath.contains(this.path)) {
      return path;
    }

    final replacement = MustacheFormat.snakeCase.toMustache('{{{$name}}}');

    final pattern = RegExp(r'(?<=[\w|}])\' + separator);

    final pathParts = path.split(pattern);

    pathParts[parts.length - 1] = replacement;

    return pathParts.join(separator);
  }
}
