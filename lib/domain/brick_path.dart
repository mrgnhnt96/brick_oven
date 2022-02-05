import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_format.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:equatable/equatable.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class BrickPath extends Equatable {
  factory BrickPath({
    required String name,
    required String path,
  }) {
    final _path = cleanPath(path);

    return BrickPath._(
      name: name,
      originalPath: path,
      path: _path,
      placeholder: basename(_path),
    );
  }

  const BrickPath._({
    required this.name,
    required this.path,
    required this.placeholder,
    required this.originalPath,
  });

  factory BrickPath.fromYaml(String path, YamlValue yaml) {
    if (extension(path).isNotEmpty) {
      throw ArgumentError.value(
        path,
        'path',
        'Path must not have an extension',
      );
    }

    String? handleYaml(YamlMap yaml) {
      final data = yaml.data;

      final name = data.remove('name') as String?;

      if (data.isNotEmpty) {
        throw ArgumentError.value(
          data.keys,
          'Unknown keys',
          'Remove all unknown keys from path $path',
        );
      }

      return name;
    }

    String? name;

    if (yaml.isYaml()) {
      name = handleYaml(yaml.asYaml().value);
    } else if (yaml.isString()) {
      name = yaml.asString().value;
    }

    name ??= basename(path);

    return BrickPath(path: path, name: name);
  }

  final String placeholder;
  final String name;
  final String path;
  final String originalPath;

  static RegExp separatorPattern = RegExp(r'(?<=[\w|}])[\/\\]');
  static RegExp slashPattern = RegExp(r'^[\/\\]+|[\/\\]+$');

  static List<String> separatePath(String path) {
    final pathParts = cleanPath(path).split(RegExp(r'[\/\\]'))
      ..removeWhere((part) => part.isEmpty);

    return pathParts;
  }

  static String cleanPath(String path) {
    final normalPath = normalize(path);
    final cleanPath = normalPath.replaceAll(slashPattern, '');

    return cleanPath;
  }

  List<String> get configuredParts => separatePath(path);

  String apply(
    String path, {
    required String originalPath,
  }) {
    final isNotFile = extension(placeholder).isNotEmpty;
    final pathsDontMatch = !originalPath.contains(this.path);

    if (isNotFile || pathsDontMatch) {
      return path;
    }

    // ignore: parameter_assignments
    path = normalize(path).replaceAll(slashPattern, '');

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
