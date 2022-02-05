// ignore_for_file: avoid_dynamic_calls

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

class BrickConfig {
  factory BrickConfig() => BrickConfig._create(const LocalFileSystem());

  @visibleForTesting
  factory BrickConfig.config(FileSystem fileSystem) =>
      BrickConfig._create(fileSystem);

  factory BrickConfig._create(FileSystem fileSystem) {
    final configFile = fileSystem.file(file);

    if (!configFile.existsSync()) {
      throw Exception('$file not found');
    }

    final config = loadYaml(configFile.readAsStringSync()) as YamlMap;

    final directories = <Brick>[];

    final data = config.data;

    final bricks = data.remove('bricks') as YamlMap?;

    if (bricks != null) {
      for (final brick in bricks.entries) {
        final name = brick.key as String;
        final value = brick.value as YamlMap?;

        directories.add(Brick.fromYaml(name, value));
      }
    }

    if (data.keys.isNotEmpty) {
      throw ArgumentError.value(
        data.keys,
        'Unknown keys',
        'Remove all unknown keys from $file',
      );
    }

    return BrickConfig._(
      directories: directories,
    );
  }

  const BrickConfig._({
    required this.directories,
  });

  final Iterable<Brick> directories;

  static const file = 'brick_oven.yaml';

  void writeMason() {
    for (final dir in directories) {
      dir.writeBrick();
    }
  }
}
