import 'package:autoequal/autoequal.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/extensions/yaml_map_extensions.dart';
import 'package:equatable/equatable.dart';
import 'package:path/path.dart';

import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/yaml_value.dart';

part 'brick_dir.g.dart';

/// {@template brick_dir}
/// The configuration of the path that will be updated to mustache
/// {@endtemplate}
@autoequal
class BrickDir extends Equatable {
  /// {@macro brick_dir}
  BrickDir({
    required String path,
    Name? name,
    String? includeIf,
    String? includeIfNot,
  }) : this._(
          name: name,
          originalPath: path,
          path: BrickDir.cleanPath(path),
          includeIf: includeIf,
          includeIfNot: includeIfNot,
        );

  BrickDir._({
    required this.name,
    required this.path,
    required this.originalPath,
    required this.includeIf,
    required this.includeIfNot,
  }) : assert(extension(path).isEmpty, 'path must not have an extension');

  /// parses the [yaml]
  factory BrickDir.fromYaml(YamlValue yaml, String path) {
    if (extension(path).isNotEmpty) {
      throw DirectoryException(
        directory: path,
        reason: 'path must not have an extension',
      );
    }

    if (yaml.isError()) {
      throw DirectoryException(
        directory: path,
        reason: 'Invalid directory: ${yaml.asError().value}',
      );
    }

    if (yaml.isNone()) {
      throw DirectoryException(
        directory: path,
        reason: 'Missing configuration, please remove this '
            'file or add configuration',
      );
    }

    if (yaml.isString()) {
      final name = Name(yaml.asString().value);

      return BrickDir(
        name: name,
        path: path,
      );
    }

    if (!yaml.isYaml()) {
      throw DirectoryException(
        directory: path,
        reason: 'Invalid directory configuration',
      );
    }

    final data = yaml.asYaml().value.data;

    Name? name;

    if (data.containsKey('name')) {
      final nameYaml = YamlValue.from(data.remove('name'));

      try {
        name = Name.fromYaml(nameYaml, basename(path));
      } on ConfigException catch (e) {
        throw DirectoryException(
          directory: path,
          reason: e.message,
        );
      }
    }

    String? getValue(String key) {
      final yaml = YamlValue.from(data.remove(key));

      if (yaml.isNone()) {
        return null;
      }

      if (!yaml.isString()) {
        throw FileException(
          file: path,
          reason: 'Expected type `String` or `null` for `$key`',
        );
      }

      return yaml.asString().value;
    }

    final includeIf = getValue('include_if');
    final includeIfNot = getValue('include_if_not');

    if (includeIf != null && includeIfNot != null) {
      throw FileException(
        file: path,
        reason: 'Cannot use both `include_if` and `include_if_not`',
      );
    }

    if (data.keys.isNotEmpty) {
      throw DirectoryException(
        directory: path,
        reason: 'Unknown keys: "${data.keys.join('", "')}"',
      );
    }

    return BrickDir(
      path: path,
      name: name,
      includeIf: includeIf,
      includeIfNot: includeIfNot,
    );
  }

  /// the pattern to remove all preceeding and trailing slashes
  static RegExp leadingAndTrailingSlashPattern = RegExp(r'^[\/\\]+|[\/\\]+$');

  /// the pattern to separate segments of a path
  static RegExp separatorPattern = RegExp(r'(?<!{+)[\/\\]');

  /// whether to include the file in the _mason_ build output
  /// based on the variable provided
  ///
  /// wraps the file in a `{{#if}}` block
  final String? includeIf;

  /// whether to include the file in the _mason_ build output
  /// based on the variable provided
  ///
  /// wraps the file in a `{{^if}}` block
  final String? includeIfNot;

  /// the name that will replace the placeholder within the [path]
  final Name? name;

  /// the non-altered (cleaned) path, which was originally provided
  final String originalPath;

  /// the path that will be updated using [name]
  ///
  /// The path MUST point to a directory, a file's path will not be altered
  final String path;

  /// the list of variables used to create the [path]
  List<String> get variables {
    final variables = <String>[];

    if (name != null) {
      variables.addAll(name!.variables);
    }

    if (includeIf != null) {
      variables.add(includeIf!);
    }

    if (includeIfNot != null) {
      variables.add(includeIfNot!);
    }

    return variables;
  }

  @override
  List<Object?> get props => _$props;

  /// applies the [path] with any configured parts from [path] and
  /// formats them with mustache
  String apply(
    String path, {
    required String originalPath,
  }) {
    final orignalParts = separatePath(originalPath);
    final configuredParts = separatePath(this.path);

    for (var i = 0;; i++) {
      if (i >= orignalParts.length) {
        if (i >= configuredParts.length) {
          break;
        }

        return path;
      }

      if (i >= configuredParts.length) {
        break;
      }

      final pathPart = orignalParts[i];
      final configuredPart = configuredParts[i];

      if (pathPart != configuredPart) {
        return path;
      }
    }

    final index = configuredParts.length - 1;
    final pathParts = separatePath(BrickDir.cleanPath(path));

    if (name != null) {
      pathParts[index] = name!.format();
    }

    if (includeIf != null) {
      pathParts[index] = '{{#$includeIf}}${pathParts[index]}{{/$includeIf}}';
    }

    if (includeIfNot != null) {
      pathParts[index] =
          '{{^$includeIfNot}}${pathParts[index]}{{/$includeIfNot}}';
    }

    final configuredPath = joinAll(pathParts);

    return configuredPath;
  }

  /// cleans the path of any strange ocurrences
  /// and preceeding & trailing slashes
  static String cleanPath(String path) {
    return path.cleanUpPath();
  }

  /// separates the path into segments
  static List<String> separatePath(String path) {
    final cleanPath = BrickDir.cleanPath(path);
    final pathParts = cleanPath.split(separatorPattern)
      ..removeWhere((part) => part.isEmpty);

    return pathParts;
  }
}

extension _StringX on String {
  /// cleans the path by removing trailing slash and
  /// ./ from the beginning
  String cleanUpPath() {
    if (this == './' || this == '.' || this == r'.\') {
      return '';
    }

    final str = normalize(this);

    return str.replaceAll(BrickDir.leadingAndTrailingSlashPattern, '');
  }
}
