// ignore_for_file: avoid_dynamic_calls

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_arguments.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

/// {@template brick_config}
/// The configuration for the brick
/// {@endtemplate}
class BrickConfig {
  /// {@macro brick_config}
  factory BrickConfig(BrickArguments arguments) => BrickConfig._create(
        const LocalFileSystem(),
        arguments: arguments,
      );

  /// Allows passing a [fileSystem] to support testing
  @visibleForTesting
  factory BrickConfig.config(
    FileSystem fileSystem, {
    BrickArguments? arguments,
  }) =>
      BrickConfig._create(
        fileSystem,
        arguments: arguments ?? const BrickArguments(),
      );

  factory BrickConfig._create(
    FileSystem fileSystem, {
    required BrickArguments arguments,
  }) {
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
      bricks: directories,
      arguments: arguments,
    );
  }

  const BrickConfig._({
    required this.bricks,
    required this.arguments,
  });

  /// the bricks that the configuration applies to
  final Iterable<Brick> bricks;

  /// the arguments provided by the package
  final BrickArguments arguments;

  /// the name of the yaml file
  static const file = 'brick_oven.yaml';

  /// writes all [bricks] to the brick dir
  Future<void> writeMason() async {
    for (final brick in bricks) {
      await brick.writeBrick(watch: arguments.watch);
    }
  }
}
