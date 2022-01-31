import 'dart:io';

import 'package:masonry/domain/masonry_variable.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class MasonryFile {
  const MasonryFile(this._path, this.target)
      : _extension = null,
        variables = null,
        _prefix = null,
        _suffix = null,
        _name = null;

  const MasonryFile._fromYaml(
    this._path, {
    required this.variables,
    required String? extension,
    required String? prefix,
    required String? suffix,
    required String? name,
    required this.target,
  })  : _extension = extension,
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

    final name = yaml['name'] as String?;
    final prefix = yaml['prefix'] as String?;
    final suffix = yaml['suffix'] as String?;
    final extension = yaml['extension'] as String?;

    return MasonryFile._fromYaml(
      path,
      variables: variables(),
      extension: extension,
      prefix: prefix,
      suffix: suffix,
      name: name,
      target: target,
    );
  }

  final String _path;
  final Iterable<MasonryVariable>? variables;
  final String? _extension;
  final String? _prefix;
  final String? _suffix;
  final String? _name;
  final String target;

  String get path {
    if (_name == null && _suffix == null && _prefix == null) {
      return _path;
    }

    return join(dirName, '');
  }

  String get fileName => basename(path);
  String get dirName => dirname(path);
  String get _filePathExtension => basename(path).split('.').last;
  String get extension => _extension ?? _filePathExtension;
  String get targetPath => join(target, path);

  String content() {
    return File(targetPath).readAsStringSync();
  }

  void writeMason(String dir) {
    final filePath = join(dir, path);
    final file = File(filePath);

    try {
      file.createSync(recursive: true);
    } catch (e) {
      print(e);
      return;
    }

    if (variables == null || variables?.isEmpty == true) {
      File(targetPath).copySync(file.path);

      return;
    }

    var content = this.content();

    // hide comments that contain
    // hide:

    for (final variable in variables!) {
      content = content.replaceAll(
        variable.placeholder,
        variable.name,
      );
    }

    file.writeAsStringSync('// this has been created\n\n$content');
  }
}
