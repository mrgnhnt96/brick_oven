// ignore_for_file: overridden_fields

import 'dart:async';

import 'package:brick_oven/domain/brick.dart';
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

/// {@template cook_single_brick_command}
/// Writes a single brick from the configuration file
/// {@endtemplate}
class CookSingleBrick extends BrickOvenCommand
    with BrickCooker, BrickCookerArgs, ConfigWatcherMixin, OvenMixin {
  /// {@macro cook_single_brick_command}
  CookSingleBrick(
    this.brick, {
    required FileSystem fileSystem,
    required Analytics analytics,
    required Logger logger,
    this.keyPressListener,
  })  : _analytics = analytics,
        super(fileSystem: fileSystem, logger: logger) {
    argParser
      ..addCookOptionsAndFlags()
      ..addSeparator('${'-' * 79}\n');
  }

  /// The brick to cook
  final Brick brick;
  final Analytics _analytics;

  @override
  final KeyPressListener? keyPressListener;

  @override
  String get description => 'Cook the brick: $name';

  @override
  String get name => brick.name;

  @override
  Future<int> run() async {
    final result = await putInOven({brick});

    unawaited(
      _analytics.sendEvent(
        'cook',
        'one',
        label: isWatch ? 'watch' : 'no-watch',
        value: result.code,
        parameters: {
          'bricks': 1.toString(),
          'sync': shouldSync.toString(),
        },
      ),
    );

    await _analytics.waitForLastPing(timeout: BrickOvenRunner.timeout);

    return result.code;
  }
}
