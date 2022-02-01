// ignore_for_file: avoid_dynamic_calls, public_member_api_docs
//
import 'dart:io';

import 'package:brick_layer/domain/brick.dart';
import 'package:yaml/yaml.dart';

class BrickConfig {
  factory BrickConfig() {
    final configFile = File('brick_layer.yaml');
    if (!configFile.existsSync()) {
      throw Exception('brick_layer.yaml not found');
    }

    final config = loadYaml(configFile.readAsStringSync()) as YamlMap;

    final directories = <Brick>[];

    if (config.containsKey('targets')) {
      final targets = config['targets'] as YamlMap;

      for (final target in targets.entries) {
        final name = target.key as String;
        final value = target.value as YamlMap;

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
