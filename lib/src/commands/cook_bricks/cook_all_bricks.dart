import 'dart:async';

import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/utils/brick_cooker.dart';
import 'package:brick_oven/utils/config_watcher_mixin.dart';
import 'package:brick_oven/utils/extensions/arg_parser_extensions.dart';
import 'package:brick_oven/utils/oven_mixin.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:usage/usage_io.dart';

/// {@template cook_all_bricks_command}
/// Writes all bricks from the configuration file
/// {@endtemplate}
class CookAllBricks extends BrickOvenCommand
    with BrickCooker, BrickCookerArgs, ConfigWatcherMixin, OvenMixin {
  /// {@macro cook_all_bricks_command}
  CookAllBricks({
    required FileSystem fileSystem,
    required Logger logger,
    required Analytics analytics,
    this.keyPressListener,
  })  : _analytics = analytics,
        super(fileSystem: fileSystem, logger: logger) {
    argParser
      ..addCookOptionsAndFlags()
      ..addSeparator('${'-' * 79}\n');
  }

  final Analytics _analytics;

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

    unawaited(
      _analytics.sendEvent(
        'cook',
        'all',
        label: isWatch ? 'watch' : 'no-watch',
        value: result.code,
        parameters: {
          'bricks': bricks.length.toString(),
        },
      ),
    );

    await _analytics.waitForLastPing(timeout: BrickOvenRunner.timeout);

    return result.code;
  }
}
