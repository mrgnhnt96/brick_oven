import 'dart:io';

import 'package:brick_layer/domain/layer_path.dart';
import 'package:brick_layer/domain/layer_variable.dart';
import 'package:brick_layer/enums/mustache_format.dart';
import 'package:brick_layer/enums/mustache_loops.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class LayerFile {
  const LayerFile(this._path, this.sourceDir)
      : variables = null,
        _prefix = null,
        _suffix = null,
        _name = null;

  const LayerFile._fromYaml(
    this._path, {
    required this.variables,
    required String? prefix,
    required String? suffix,
    required String? name,
    required this.sourceDir,
  })  : _prefix = prefix,
        _suffix = suffix,
        _name = name;

  const LayerFile._({
    required this.variables,
    required String? prefix,
    required String? suffix,
    required String? name,
    required this.sourceDir,
    required String path,
  })  : _path = path,
        _prefix = prefix,
        _suffix = suffix,
        _name = name;

  factory LayerFile.fromYaml(String path, String target, YamlMap yaml) {
    Iterable<LayerVariable> variables() sync* {
      if (!yaml.containsKey('vars')) {
        return;
      }

      final variables = yaml['vars'] as YamlMap;

      for (final entry in variables.entries) {
        final name = entry.key as String;
        final value = entry.value as YamlMap;

        yield LayerVariable.fromYaml(name, value);
      }
    }

    final fileConfig = yaml['file'] as YamlMap?;

    final name = fileConfig?.value['name'] as String?;
    final prefix = fileConfig?.value['prefix'] as String?;
    final suffix = fileConfig?.value['suffix'] as String?;

    return LayerFile._fromYaml(
      path,
      variables: variables(),
      prefix: prefix,
      suffix: suffix,
      name: name,
      sourceDir: target,
    );
  }

  final String _path;
  final Iterable<LayerVariable>? variables;
  final String? _prefix;
  final String? _suffix;
  final String? _name;
  final String sourceDir;

  String get fileName {
    if (_name == null) {
      return basename(_path);
    }
    final prefix = _prefix ?? '';
    final suffix = _suffix ?? '';

    final name = '$prefix{{{$_name}}}$suffix';
    final formattedName = MustacheFormat.snakeCase.toMustache(name);

    return '$formattedName$_preExtension$_extension';
  }

  String get targetDir {
    final dir = dirname(_path);
    if (dir == '.') {
      return '';
    }

    return dir;
  }

  String get _extension => extension(_path);
  String get _preExtension {
    final base = basenameWithoutExtension(_path);
    if (!base.contains('.')) {
      return '';
    }

    return base.substring(base.indexOf('.'));
  }

  String get sourcePath => join(sourceDir, _path);
  String get targetPath => join(targetDir, fileName);

  String content() {
    return File(sourcePath).readAsStringSync();
  }

  void writeMason(
    String targetDir,
    Iterable<LayerPath> layerPaths,
  ) {
    var path = join(targetDir, targetPath);

    for (final layerPath in layerPaths) {
      path = layerPath.apply(path);
    }

    final file = File(path);

    try {
      file.createSync(recursive: true);
    } catch (e) {
      print(e);
      return;
    }

    if (variables == null || variables?.isEmpty == true) {
      File(sourcePath).copySync(file.path);

      return;
    }

    var content = this.content();

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
