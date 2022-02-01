import 'dart:io';

import 'package:brick_layer/domain/brick_path.dart';
import 'package:brick_layer/domain/variable.dart';
import 'package:brick_layer/enums/mustache_format.dart';
import 'package:brick_layer/enums/mustache_loops.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class BrickFile {
  const BrickFile(this.path)
      : variables = null,
        _prefix = null,
        _suffix = null,
        _name = null;

  const BrickFile._fromYaml(
    this.path, {
    required this.variables,
    required String? prefix,
    required String? suffix,
    required String? name,
  })  : _prefix = prefix,
        _suffix = suffix,
        _name = name;

  const BrickFile._({
    required this.variables,
    required String? prefix,
    required String? suffix,
    required String? name,
    required this.path,
  })  : _prefix = prefix,
        _suffix = suffix,
        _name = name;

  factory BrickFile.fromYaml(
    YamlMap yaml, {
    required String path,
  }) {
    Iterable<Variable> variables() sync* {
      if (!yaml.containsKey('vars')) {
        return;
      }

      final variables = yaml['vars'] as YamlMap;

      for (final entry in variables.entries) {
        final name = entry.key as String;
        final value = entry.value as YamlMap;

        yield Variable.fromYaml(name, value);
      }
    }

    final fileConfig = yaml['file'] as YamlMap?;

    final name = fileConfig?.value['name'] as String?;
    final prefix = fileConfig?.value['prefix'] as String?;
    final suffix = fileConfig?.value['suffix'] as String?;

    return BrickFile._fromYaml(
      path,
      variables: variables(),
      prefix: prefix,
      suffix: suffix,
      name: name,
    );
  }

  final String path;
  final Iterable<Variable>? variables;
  final String? _prefix;
  final String? _suffix;
  final String? _name;

  String get fileName {
    if (_name == null) {
      return basename(path);
    }
    final prefix = _prefix ?? '';
    final suffix = _suffix ?? '';

    final name = '$prefix{{{$_name}}}$suffix';
    final formattedName = MustacheFormat.snakeCase.toMustache(name);

    return '$formattedName$_extension';
  }

  String get _extension => extension(path, 10);

  void writeTargetFile({
    required String targetDir,
    required File sourceFile,
    required Iterable<BrickPath> configuredDirs,
  }) {
    var path = this.path;

    if (path.contains(separator)) {
      final originalPath = path;

      for (final layerPath in configuredDirs) {
        path = layerPath.apply(path, originalPath: originalPath);
      }
    }

    final file = File(join(targetDir, path));

    try {
      file.createSync(recursive: true);
    } catch (e) {
      print(e);
      return;
    }

    if (variables == null || variables?.isEmpty == true) {
      sourceFile.copySync(file.path);

      return;
    }

    var content = sourceFile.readAsStringSync();

    for (final variable in variables!) {
      final pattern = RegExp('(.*)${variable.placeholder}' r'(\w*!?)(.*)');
      content = content.replaceAllMapped(pattern, (match) {
        final value = match.group(2);

        final loop = MustacheLoops.values.retrieve(value);
        if (loop != null) {
          return MustacheLoops.toMustache(variable.name, () => loop);
        }

        final format = MustacheFormat.values.retrieve('${value}Case');

        String result;
        if (format == null) {
          result = variable.formattedName;
        } else {
          result = variable.formatName(format);
        }

        final prefix = match.group(1) ?? '';
        final suffix = match.group(3) ?? '';

        return '$prefix$result$suffix';
      });
    }

    file.writeAsStringSync(content);
  }
}
