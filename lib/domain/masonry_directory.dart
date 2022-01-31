import 'dart:io';

import 'package:masonry/domain/masonry_file.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class MasonryDirectory {
  const MasonryDirectory(
    this.path,
  )   : _masonryFiles = const <String, MasonryFile>{},
        _name = null;

  const MasonryDirectory._fromYaml(
    this.path,
    this._masonryFiles,
    this._name,
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

    final name = yaml.value['name'] as String?;

    return MasonryDirectory._fromYaml(
      path,
      files(),
      name,
    );
  }

  final String path;
  final Map<String, MasonryFile> _masonryFiles;
  final String? _name;

  Iterable<MasonryFile> files() {
    final dir = Directory(path);

    if (!dir.existsSync()) {
      return {};
    }

    final files = dir.listSync(recursive: true)
      ..removeWhere((element) => element is Directory);

    final masonryFiles = {
      for (final file in files)
        file.path:
            MasonryFile(file.path.replaceFirst('$path$separator', ''), path)
    }..removeWhere((key, _) => key.contains('.dart_tool'));

    final masonry = <String, MasonryFile>{}
      ..addAll(masonryFiles)
      ..addAll(_masonryFiles);

    return masonry.values;
  }

  String get root => dirname(path);

  void writeMason() {
    var name = _name ?? root;
    if (name == '.') {
      name = path;
    }

    final dir = join(
      'bricks',
      name,
      '__brick__',
    );

    print('writing $name');

    for (final file in files()) {
      file.writeMason(dir);
    }

    _writeAnalysis();

    print('complete!');
  }

  void _writeAnalysis() {
    final newAnalysisOptions = File(join('bricks', 'analysis_options.yaml'));

    if (!newAnalysisOptions.existsSync()) {
      newAnalysisOptions.writeAsStringSync(
        '''
analyzer:
  exclude:
    - "**/*.dart"''',
      );

      return;
    }
  }
}
