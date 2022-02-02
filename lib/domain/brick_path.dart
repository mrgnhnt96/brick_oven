import 'package:brick_oven/enums/mustache_format.dart';
import 'package:equatable/equatable.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class BrickPath extends Equatable {
  factory BrickPath({
    required String name,
    required String path,
  }) {
    final _path = path.replaceAll(slashPattern, '');

    return BrickPath._(
      name: name,
      path: _path,
      placeholder: _path.substring(_path.lastIndexOf(separator) + 1),
    );
  }

  const BrickPath._({
    required this.name,
    required this.path,
    required this.placeholder,
  });

  factory BrickPath.fromYaml(String path, dynamic yaml) {
    String? handleYaml(YamlMap yaml) {
      final data = yaml.value;

      final name = data.remove('name') as String?;

      if (data.isNotEmpty) {
        throw ArgumentError('Unknown keys in path: ${data.keys}');
      }

      return name;
    }

    String? name;
    switch (yaml.runtimeType) {
      case String:
        name = yaml as String;
        break;
      case YamlMap:
        name = handleYaml(yaml as YamlMap);
        break;
    }

    name ??= basename(path);

    return BrickPath(path: path, name: name);
  }

  final String placeholder;
  final String name;
  final String path;

  static RegExp separatorPattern = RegExp(r'(?<=[\w|}])\' + separator);
  static RegExp slashPattern =
      RegExp(r'^\' + separator + r'|\' + separator + r'$');

  List<String> get configuredParts => path.split(separatorPattern);

  String apply(
    String path, {
    required String originalPath,
  }) {
    final isNotFile = extension(placeholder).isNotEmpty;
    final isNotDirectoryDeep = !this.path.contains(separatorPattern);
    final pathsDontMatch = !originalPath.contains(this.path);

    if (isNotFile || isNotDirectoryDeep || pathsDontMatch) {
      return path;
    }

    // ignore: parameter_assignments
    path = path.replaceAll(slashPattern, '');

    final replacement = MustacheFormat.snakeCase.toMustache('{{{$name}}}');

    final pathParts = path.split(separatorPattern);

    if (pathParts.length < configuredParts.length) {
      return path;
    }

    if (pathParts[configuredParts.length - 1] == placeholder) {
      pathParts[configuredParts.length - 1] = replacement;
    }

    return pathParts.join(separator);
  }

  @override
  List<Object?> get props => [name, path, placeholder];
}
