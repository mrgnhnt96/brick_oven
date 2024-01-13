import 'dart:async';

import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/domain/implementations/brick_impl.dart';
import 'package:brick_oven/domain/interfaces/brick.dart';
import 'package:brick_oven/domain/config/brick_oven_config.dart';
import 'package:brick_oven/utils/yaml_to_json.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/utils/brick_cooker.dart';
import 'package:brick_oven/utils/config_watcher_mixin.dart';
import 'package:brick_oven/utils/extensions/arg_parser_extensions.dart';
import 'package:brick_oven/utils/oven_mixin.dart';

/// {@template cook_all_bricks_command}
/// Writes all bricks from the configuration file
/// {@endtemplate}
class CookAllBricks extends BrickOvenCommand
    with
        BrickCooker,
        BrickCookerArgs,
        ConfigWatcherMixin,
        LoggerMixin,
        OvenMixin {
  /// {@macro cook_all_bricks_command}
  CookAllBricks({
    this.keyPressListener,
  }) {
    argParser
      ..addCookOptionsAndFlags()
      ..addSeparator('${'-' * 79}\n');
  }

  @override
  final KeyPressListener? keyPressListener;

  @override
  String get description => 'Cook all bricks';

  @override
  String get name => 'all';

  @override
  Future<int> run() async {
    final configFile = BrickOvenYaml.findNearest(cwd);

    if (configFile == null) {
      throw Exception('Config file not found');
    }

    final json = YamlToJson.fromFile(configFile);

    final config = BrickOvenConfig.fromJson(json, configPath: configFile.path);

    final bricks = <Brick>{};

    for (final MapEntry(key: name, value: config)
        in config.resolveBricks().entries) {
      bricks.add(
        BrickImpl(
          config,
          name: name,
          outputDir: outputDir,
          watch: isWatch,
          shouldSync: shouldSync,
        ),
      );
    }

    final result = await putInOven(bricks);

    return result.code;
  }
}
