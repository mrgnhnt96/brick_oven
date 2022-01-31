import 'package:yaml/yaml.dart';

class MasonryPath {
  const MasonryPath({
    required this.part,
    required this.path,
    required this.name,
  });

  factory MasonryPath.fromYaml(String path, YamlMap yaml) {
    final part = yaml['part'] as String;
    final name = yaml['name'] as String;

    return MasonryPath(
      part: part,
      path: path,
      name: name,
    );
  }

  final String path;
  final String part;
  final String name;

  String get replacedPath {
    final pattern = RegExp(r'\b' + part + r'\b');

    return path.replaceAll(pattern, '{{$name}}');
  }
}
