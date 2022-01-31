import 'dart:io';

import 'package:masonry/domain/masonry_path.dart';
import 'package:masonry/domain/masonry_variable.dart';
import 'package:masonry/enums/mason_format.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class MasonryFile {
  const MasonryFile(this._path, this.sourceDir)
      : variables = null,
        _prefix = null,
        _suffix = null,
        _name = null;

  const MasonryFile._fromYaml(
    this._path, {
    required this.variables,
    required String? prefix,
    required String? suffix,
    required String? name,
    required this.sourceDir,
  })  : _prefix = prefix,
        _suffix = suffix,
        _name = name;

  const MasonryFile._({
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

  factory MasonryFile.fromYaml(String path, String target, YamlMap yaml) {
    Iterable<MasonryVariable> variables() sync* {
      if (!yaml.containsKey('vars')) {
        return;
      }

      final variables = yaml['vars'] as YamlMap;

      for (final entry in variables.entries) {
        final name = entry.key as String;
        final value = entry.value as YamlMap;

        yield MasonryVariable.fromYaml(name, value);
      }
    }

    final fileConfig = yaml['file'] as YamlMap?;

    final name = fileConfig?.value['name'] as String?;
    final prefix = fileConfig?.value['prefix'] as String?;
    final suffix = fileConfig?.value['suffix'] as String?;

    return MasonryFile._fromYaml(
      path,
      variables: variables(),
      prefix: prefix,
      suffix: suffix,
      name: name,
      sourceDir: target,
    );
  }

  final String _path;
  final Iterable<MasonryVariable>? variables;
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

    final name = MasonFormat.snakeCase.toMustache('{$_name}');

    return '$prefix$name$suffix$_preExtension$_extension';
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
    Iterable<MasonryPath> masonryPaths,
  ) {
    var path = join(targetDir, targetPath);

    for (final masonryPath in masonryPaths) {
      path = masonryPath.apply(path);
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
      final pattern = RegExp(variable.placeholder + r'(\w*)');
      content = content.replaceAllMapped(pattern, (match) {
        print(match);
        final value = match.group(1);

        final format = MasonFormat.values.retrieve('${value}Case');

        if (format == null) {
          return variable.formattedName;
        }

        return variable.formatName(format);
      });
    }

    file.writeAsStringSync('// this has been created\n\n$content');
  }
}
