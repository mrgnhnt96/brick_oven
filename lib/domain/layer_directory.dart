import 'dart:io';

import 'package:brick_layer/domain/layer_file.dart';
import 'package:brick_layer/domain/layer_path.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class LayerDirectory {
  const LayerDirectory(
    this.sourcePath,
  )   : _masonryFiles = const <String, LayerFile>{},
        dirs = const <LayerPath>{},
        _targetDir = null;

  const LayerDirectory._fromYaml(
    this.sourcePath,
    this._masonryFiles,
    this._targetDir,
    this.dirs,
  );

  factory LayerDirectory.fromYaml(String path, YamlMap yaml) {
    Map<String, LayerFile> files() {
      final files = <String, LayerFile>{};

      if (!yaml.containsKey('files')) {
        return files;
      }

      final value = yaml['files'] as YamlMap;

      for (final entry in value.entries) {
        final name = entry.key as String;
        final value = entry.value as YamlMap;

        files[join(path, name)] = LayerFile.fromYaml(name, path, value);
      }
      return files;
    }

    Iterable<LayerPath> paths() sync* {
      if (!yaml.containsKey('directories')) {
        return;
      }

      final value = yaml['directories'] as YamlMap;

      for (final entry in value.entries) {
        final path = entry.key as String;
        final value = entry.value as YamlMap;

        yield LayerPath.fromYaml(path, value);
      }
    }

    final name = yaml.value['name'] as String?;

    return LayerDirectory._fromYaml(
      path,
      files(),
      name,
      paths(),
    );
  }

  final String sourcePath;
  final Map<String, LayerFile> _masonryFiles;
  final String? _targetDir;
  final Iterable<LayerPath> dirs;

  Iterable<LayerFile> files() {
    final dir = Directory(sourcePath);

    if (!dir.existsSync()) {
      return {};
    }

    final files = dir.listSync(recursive: true)
      ..removeWhere((element) => element is Directory);

    final masonryFiles = {
      for (final file in files)
        file.path: LayerFile(
          file.path.replaceFirst('$sourcePath$separator', ''),
          sourcePath,
        )
    };

    final masonry = <String, LayerFile>{}
      ..addAll(masonryFiles)
      ..addAll(_masonryFiles);

    return masonry.values;
  }

  String get root => dirname(sourcePath);

  void writeMason() {
    var name = _targetDir ?? root;
    if (name == '.') {
      name = sourcePath;
    }

    final dir = join(
      'bricks',
      name,
      '__brick__',
    );

    final directory = Directory(dir);
    if (directory.existsSync()) {
      print('deleting ${directory.path}');

      directory.deleteSync(recursive: true);
    }

    print('writing $name');

    for (final file in files()) {
      file.writeMason(dir, dirs);
    }

    _writeAnalysis();

    print('complete!');
  }

  void _writeAnalysis() {
    File(join('bricks', 'analysis_options.yaml'))
      ..createSync()
      ..writeAsStringSync(
        '''
analyzer:
  exclude:
    - "**/*.dart"''',
      );

    return;
  }
}
