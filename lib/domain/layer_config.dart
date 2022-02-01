// ignore_for_file: avoid_dynamic_calls, public_member_api_docs
//
import 'dart:io';

import 'package:brick_layer/domain/layer_directory.dart';
import 'package:yaml/yaml.dart';

class LayerConfig {
  factory LayerConfig() {
    final configFile = File('brick_layer.yaml');
    if (!configFile.existsSync()) {
      throw Exception('brick_layer.yaml not found');
    }

    final config = loadYaml(configFile.readAsStringSync()) as YamlMap;

    final directories = <LayerDirectory>[];

    if (config.containsKey('targets')) {
      final targets = config['targets'] as YamlMap;

      for (final target in targets.entries) {
        final name = target.key as String;
        final value = target.value as YamlMap;

        directories.add(LayerDirectory.fromYaml(name, value));
      }
    }

    return LayerConfig._(
      directories: directories,
    );
  }

  const LayerConfig._({
    required this.directories,
  });

  final Iterable<LayerDirectory> directories;

  void writeMason() {
    for (final dir in directories) {
      dir.writeBrick();
    }
  }
}
