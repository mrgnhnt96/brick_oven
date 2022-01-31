import 'dart:io';

import 'package:masonry/domain/masonry_file.dart';
import 'package:masonry/domain/masonry_path.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class MasonryDirectory {
  const MasonryDirectory(
    this.sourcePath,
  )   : _masonryFiles = const <String, MasonryFile>{},
        dirs = const <MasonryPath>{},
        _targetDir = null;

  const MasonryDirectory._fromYaml(
    this.sourcePath,
    this._masonryFiles,
    this._targetDir,
    this.dirs,
  );

  factory MasonryDirectory.fromYaml(String path, YamlMap yaml) {
    Map<String, MasonryFile> files() {
      final files = <String, MasonryFile>{};

      if (!yaml.containsKey('files')) {
        return files;
      }

      final value = yaml['files'] as YamlMap;

      for (final entry in value.entries) {
        final name = entry.key as String;
        final value = entry.value as YamlMap;

        files[join(path, name)] = MasonryFile.fromYaml(name, path, value);
      }
      return files;
    }

    Iterable<MasonryPath> paths() sync* {
      if (!yaml.containsKey('directories')) {
        return;
      }

      final value = yaml['directories'] as YamlMap;

      for (final entry in value.entries) {
        final path = entry.key as String;
        final value = entry.value as YamlMap;

        yield MasonryPath.fromYaml(path, value);
      }
    }

    final name = yaml.value['name'] as String?;

    return MasonryDirectory._fromYaml(
      path,
      files(),
      name,
      paths(),
    );
  }

  final String sourcePath;
  final Map<String, MasonryFile> _masonryFiles;
  final String? _targetDir;
  final Iterable<MasonryPath> dirs;

  Iterable<MasonryFile> files() {
    final dir = Directory(sourcePath);

    if (!dir.existsSync()) {
      return {};
    }

    final files = dir.listSync(recursive: true)
      ..removeWhere((element) => element is Directory);

    final masonryFiles = {
      for (final file in files)
        file.path: MasonryFile(
          file.path.replaceFirst('$sourcePath$separator', ''),
          sourcePath,
        )
    };

    final masonry = <String, MasonryFile>{}
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

      // TODO(mrgnhnt96): ask for permission?
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
