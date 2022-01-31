// ignore_for_file: avoid_dynamic_calls, public_member_api_docs
//
import 'dart:io';

import 'package:masonry/domain/masonry_directory.dart';
import 'package:yaml/yaml.dart';

class MasonryConfig {
  factory MasonryConfig() {
    final configFile = File('masonry.yaml');
    if (!configFile.existsSync()) {
      throw Exception('masonry.yaml not found');
    }

    final config = loadYaml(configFile.readAsStringSync()) as YamlMap;

    final directories = <MasonryDirectory>[];

    if (config.containsKey('targets')) {
      final targets = config['targets'] as YamlMap;

      for (final target in targets.entries) {
        final name = target.key as String;
        final value = target.value as YamlMap;

        directories.add(MasonryDirectory.fromYaml(name, value));
      }
    }

    return MasonryConfig._(
      directories: directories,
    );
  }

  const MasonryConfig._({
    required this.directories,
  });

  final Iterable<MasonryDirectory> directories;

  void writeMason() {
    for (final dir in directories) {
      dir.writeMason();
    }
  }
}
