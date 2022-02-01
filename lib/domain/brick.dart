import 'dart:io';

import 'package:brick_layer/domain/brick_file.dart';
import 'package:brick_layer/domain/brick_path.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class Brick {
  const Brick(
    this.sourcePath,
  )   : _layerFiles = const <String, BrickFile>{},
        layerDirs = const <BrickPath>{},
        _targetDir = null;

  const Brick._fromYaml(
    this.sourcePath,
    this._layerFiles,
    this._targetDir,
    this.layerDirs,
  );

  factory Brick.fromYaml(String path, YamlMap yaml) {
    Map<String, BrickFile> files() {
      final files = <String, BrickFile>{};

      if (!yaml.containsKey('files')) {
        return files;
      }

      final value = yaml['files'] as YamlMap;

      for (final entry in value.entries) {
        final name = entry.key as String;
        final value = entry.value as YamlMap;

        files[join(path, name)] = BrickFile.fromYaml(name, path, value);
      }
      return files;
    }

    Iterable<BrickPath> paths() sync* {
      if (!yaml.containsKey('directories')) {
        return;
      }

      final value = yaml['directories'] as YamlMap;

      for (final entry in value.entries) {
        final path = entry.key as String;
        final value = entry.value as YamlMap;

        yield BrickPath.fromYaml(path, value);
      }
    }

    final name = yaml.value['name'] as String?;

    return Brick._fromYaml(
      path,
      files(),
      name,
      paths(),
    );
  }

  final String sourcePath;
  final Map<String, BrickFile> _layerFiles;
  final String? _targetDir;
  final Iterable<BrickPath> layerDirs;

  Iterable<BrickFile> files() {
    final dir = Directory(sourcePath);

    if (!dir.existsSync()) {
      return {};
    }

    final files = dir.listSync(recursive: true)
      ..removeWhere((element) => element is Directory);

    final layerFiles = {
      for (final file in files)
        file.path: BrickFile(
          file.path.replaceFirst('$sourcePath$separator', ''),
          sourcePath,
        )
    };

    final layer = <String, BrickFile>{}
      ..addAll(layerFiles)
      ..addAll(_layerFiles);

    return layer.values;
  }

  String get root => dirname(sourcePath);

  void writeBrick() {
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
      file.writeTargetFile(dir, layerDirs);
    }

    print('complete!');
  }
}
