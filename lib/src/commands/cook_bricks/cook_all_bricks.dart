import 'dart:async';

import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/utils/brick_cooker.dart';
import 'package:brick_oven/utils/config_watcher_mixin.dart';
import 'package:brick_oven/utils/extensions/arg_parser_extensions.dart';
import 'package:brick_oven/utils/oven_mixin.dart';
import 'package:mason_logger/mason_logger.dart';

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
    final bricksOrError = this.bricks();
    if (bricksOrError.isError) {
      logger.err(bricksOrError.error);
      return ExitCode.config.code;
    }

    final bricks = bricksOrError.bricks;

    final result = await putInOven(bricks);

    return result.code;
  }
}
