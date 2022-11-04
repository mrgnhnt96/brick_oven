import 'package:autoequal/autoequal.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:equatable/equatable.dart';
import 'package:path/path.dart';

import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/yaml_value.dart';

part 'brick_path.g.dart';

/// {@template brick_path}
/// The configuration of the path that will be updated to mustache
/// {@endtemplate}
@autoequal
class BrickPath extends Equatable {
  /// {@macro brick_path}
  factory BrickPath({
    required Name name,
    required String path,
  }) {
    final cleanPath = BrickPath.cleanPath(path);

    return BrickPath._(
      name: name,
      originalPath: path,
      path: cleanPath,
      placeholder: basename(cleanPath),
    );
  }

  const BrickPath._({
    required this.name,
    required this.path,
    required this.placeholder,
    required this.originalPath,
  });

  /// parses the [yaml]
  factory BrickPath.fromYaml(YamlValue yaml, String path) {
    if (yaml.isError()) {
      throw DirectoryException(
        directory: path,
        reason: 'Invalid directory: ${yaml.asError().value}',
      );
    }

    if (extension(path).isNotEmpty) {
      throw DirectoryException(
        directory: path,
        reason: 'the path must point to a directory',
      );
    }

    Name name;

    if (yaml.isYaml()) {
      final data = yaml.asYaml().value.data;
      final nameData = YamlValue.from(data.remove('name'));

      if (data.keys.isNotEmpty) {
        throw DirectoryException(
          directory: path,
          reason: 'Unknown keys: "${data.keys.join('", "')}"',
        );
      }

      name = Name.fromYaml(nameData, basename(path));
    } else if (yaml.isString()) {
      name = Name(yaml.asString().value);
    } else {
      name = Name(basename(path));
    }

    return BrickPath(
      path: path,
      name: name,
    );
  }

  /// the pattern to separate segments of a path
  static RegExp separatorPattern = RegExp(r'(?<=[\w|}])[\/\\]');

  /// the pattern to remove all preceeding and trailing slashes
  static RegExp slashPattern = RegExp(r'^[\/\\]+|[\/\\]+$');

  /// the name that will replace the [placeholder] within the [path]
  final Name name;

  /// the non-altered (cleaned) path, which was originally provided
  final String originalPath;

  /// the path that will be updated using [name]
  ///
  /// The path MUST point to a directory, a file's path will not be altered
  final String path;

  /// the placeholder of the [path] that will be replaced with [name]
  ///
  /// The placeholder MUST be a directory
  final String placeholder;

  @override
  List<Object?> get props => _$props;

  /// the segments of [path]
  List<String> get configuredParts => separatePath(path);

  /// applies the [path] with any [configuredParts] and
  /// formats them with mustache
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

    final replacement = name.formatted;

    final pathParts = path.split(separatorPattern);

    if (pathParts.length < configuredParts.length) {
      return path;
    }

    if (pathParts[configuredParts.length - 1] == placeholder) {
      pathParts[configuredParts.length - 1] = replacement;
    }

    return pathParts.join(separator);
  }

  /// cleans the path of any strange ocurrences
  /// and preceeding & trailing slashes
  static String cleanPath(String path) {
    final normalPath = normalize(path);
    final cleanPath = normalPath.replaceAll(slashPattern, '');
    final purePath = cleanPath.cleanUpPath();

    return purePath;
  }

  /// separates the path into segments
  static List<String> separatePath(String path) {
    final pathParts = cleanPath(path).split(RegExp(r'[\/\\]'))
      ..removeWhere((part) => part.isEmpty);

    return pathParts;
  }
}

extension _StringX on String {
  /// cleans the path by removing trailing slash and
  /// ./ from the beginning
  String cleanUpPath() {
    String removeLast(String path) {
      if (path.endsWith('/') || path.endsWith('.')) {
        return removeLast(path.substring(0, path.length - 1));
      }

      return path;
    }

    var str = normalize(this);

    if (this == './') {
      return '';
    }

    return str = removeLast(str);
  }
}
