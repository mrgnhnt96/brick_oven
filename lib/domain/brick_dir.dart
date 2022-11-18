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
  factory BrickDir({
    required String path,
    Name? name,
    String? includeIf,
    String? includeIfNot,
  }) {
    final cleanPath = BrickDir.cleanPath(path);

    return BrickDir._(
      name: name,
      originalPath: path,
      path: cleanPath,
      placeholder: basename(cleanPath),
      includeIf: includeIf,
      includeIfNot: includeIfNot,
    );
  }

  const BrickDir._({
    required this.name,
    required this.path,
    required this.placeholder,
    required this.originalPath,
    required this.includeIf,
    required this.includeIfNot,
  });

  /// parses the [yaml]
  factory BrickDir.fromYaml(YamlValue yaml, String path) {
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
  static RegExp separatorPattern = RegExp(r'[\/\\]');

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

  /// the name that will replace the [placeholder] within the [path]
  final Name? name;

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
    path = BrickDir.cleanPath(path);

    final replacement = name?.formatted;

    final pathParts = BrickDir.separatePath(path);

    if (pathParts.length < configuredParts.length) {
      return path;
    }

    if (replacement != null) {
      if (pathParts[configuredParts.length - 1] == placeholder) {
        pathParts[configuredParts.length - 1] = replacement;
      }
    }

    final configuredPath = pathParts.join(separator);

    if (includeIf != null) {
      return '{{#$includeIf}}$configuredPath{{/$includeIf}}';
    }

    if (includeIfNot != null) {
      return '{{^$includeIfNot}}$configuredPath{{/$includeIfNot}}';
    }

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
