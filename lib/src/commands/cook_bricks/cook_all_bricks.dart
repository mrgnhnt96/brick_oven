import 'dart:async';

import 'package:brick_oven/domain/implementations/brick_impl.dart';
import 'package:brick_oven/domain/interfaces/brick.dart';
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

  bool _hasWarned = false;

  @override
  Future<int> run() async {
    final config = getBrickOvenConfig();

    if (config == null) {
      if (!_hasWarned) {
        _hasWarned = true;
        logger.err('Failed to parse config file');
      }
      return 1;
    }

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
