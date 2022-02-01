// ignore_for_file: avoid_dynamic_calls, public_member_api_docs
//
import 'dart:io';

import 'package:brick_oven/domain/brick.dart';
import 'package:yaml/yaml.dart';

class BrickConfig {
  factory BrickConfig() {
    final configFile = File('brick_oven.yaml');
    if (!configFile.existsSync()) {
      throw Exception('brick_oven.yaml not found');
    }

    final config = loadYaml(configFile.readAsStringSync()) as YamlMap;

    final directories = <Brick>[];

    if (config.containsKey('bricks')) {
      final bricks = config['bricks'] as YamlMap;

      for (final brick in bricks.entries) {
        final name = brick.key as String;
        final value = brick.value as YamlMap;

        directories.add(Brick.fromYaml(name, value));
      }
    }

    return BrickConfig._(
      directories: directories,
    );
  }

  const BrickConfig._({
    required this.directories,
  });

  final Iterable<Brick> directories;

  void writeMason() {
    for (final dir in directories) {
      dir.writeBrick();
    }
  }
}
