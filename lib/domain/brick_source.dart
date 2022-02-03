import 'dart:io';

import 'package:brick_oven/domain/brick_file.dart';
import 'package:equatable/equatable.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class BrickSource extends Equatable {
  const BrickSource({
    required this.localPath,
  });

  const BrickSource.none() : localPath = null;

  factory BrickSource.fromYaml(dynamic yaml) {
    BrickSource handleYaml(YamlMap yaml) {
      final data = yaml.value;

      final localPath = data.remove('path') as String?;

      if (data.isNotEmpty) {
        throw ArgumentError('Unknown keys in source: ${data.keys}');
      }

      return BrickSource(localPath: localPath);
    }

    switch (yaml.runtimeType) {
      case String:
        return BrickSource(localPath: yaml as String);
      case YamlMap:
        return handleYaml(yaml as YamlMap);
      default:
        return const BrickSource.none();
    }
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

  String fromSourcePath(BrickFile file) {
    return join(sourceDir, file.path);
  }

  @override
  List<Object?> get props => [localPath];
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
