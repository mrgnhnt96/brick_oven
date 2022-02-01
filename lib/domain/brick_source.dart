import 'dart:io';

import 'package:brick_layer/domain/brick_file.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class BrickSource {
  const BrickSource({
    required this.localPath,
  });

  factory BrickSource.fromYaml(YamlMap yaml) {
    final path = yaml.value['source'] as String?;

    return BrickSource(
      localPath: path,
    );
  }

  final String? localPath;

  Iterable<BrickFile> files() sync* {
    if (localPath == null) {
      return;
    }

    yield* _fromDir();
  }

  String get sourceDir {
    if (localPath == null) {
      return '';
    }

    return localPath!;
  }

  Iterable<BrickFile> mergeFilesAndConfig(Iterable<BrickFile> configFiles) {
    final configs = configFiles.toMap();

    Map<String, BrickFile> sourceFiles;

    if (localPath != null) {
      sourceFiles = _fromDir().toMap();
    } else {
      sourceFiles = <String, BrickFile>{};
    }

    final result = <String, BrickFile>{}
      ..addAll(sourceFiles)
      ..addAll(configs);

    return result.values;
  }

  Iterable<BrickFile> _fromDir() sync* {
    final localPath = this.localPath;
    if (localPath == null) {
      throw Exception('path is null');
    }

    final dir = Directory(localPath);

    if (!dir.existsSync()) {
      return;
    }

    final files = dir.listSync(recursive: true)
      ..removeWhere((element) => element is Directory);

    for (final file in files) {
      yield BrickFile(file.path.replaceFirst(RegExp('$localPath.'), ''));
    }
  }

  File from(BrickFile file) {
    return File(join(sourceDir, file.path));
  }
}

extension on Iterable<BrickFile> {
  Map<String, BrickFile> toMap() {
    return fold<Map<String, BrickFile>>(
      <String, BrickFile>{},
      (Map<String, BrickFile> map, BrickFile file) {
        map[file.path] = file;
        return map;
      },
    );
  }
}
