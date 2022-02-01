import 'dart:io';

import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_path.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class Brick {
  const Brick._fromYaml({
    required this.name,
    required this.source,
    required this.configuredFiles,
    required this.configuredDirs,
  });

  factory Brick.fromYaml(String name, YamlMap yaml) {
    final source = BrickSource.fromYaml(yaml);

    Iterable<BrickFile> files() sync* {
      if (!yaml.containsKey('files')) {
        return;
      }

      final value = yaml['files'] as YamlMap;

      for (final entry in value.entries) {
        final path = entry.key as String;
        final yaml = entry.value as YamlMap;

        yield BrickFile.fromYaml(yaml, path: path);
      }
    }

    Iterable<BrickPath> paths() sync* {
      if (!yaml.containsKey('dirs')) {
        return;
      }

      final value = yaml['dirs'] as YamlMap;

      for (final entry in value.entries) {
        final path = entry.key as String;
        final value = entry.value as YamlMap;

        yield BrickPath.fromYaml(path, value);
      }
    }

    return Brick._fromYaml(
      configuredFiles: files(),
      source: source,
      name: name,
      configuredDirs: paths(),
    );
  }

  final String name;
  final BrickSource source;
  final Iterable<BrickFile> configuredFiles;
  final Iterable<BrickPath> configuredDirs;

  void writeBrick() {
    final targetDir = join(
      'bricks',
      name,
      '__brick__',
    );

    final directory = Directory(targetDir);
    if (directory.existsSync()) {
      print('deleting ${directory.path}');

      directory.deleteSync(recursive: true);
    }

    print('writing $name');

    for (final file in source.mergeFilesAndConfig(configuredFiles)) {
      file.writeTargetFile(
        targetDir: targetDir,
        sourceFile: source.from(file),
        configuredDirs: configuredDirs,
      );
    }

    print('complete!');
  }
}
