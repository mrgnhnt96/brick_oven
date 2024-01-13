// ignore_for_file: overridden_fields

import 'dart:async';

import 'package:brick_oven/domain/implementations/brick_impl.dart';
import 'package:brick_oven/domain/config/brick_config.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/utils/brick_cooker.dart';
import 'package:brick_oven/utils/config_watcher_mixin.dart';
import 'package:brick_oven/utils/extensions/arg_parser_extensions.dart';
import 'package:brick_oven/utils/oven_mixin.dart';

/// {@template cook_single_brick_command}
/// Writes a single brick from the configuration file
/// {@endtemplate}
class CookSingleBrick extends BrickOvenCommand
    with
        BrickCooker,
        BrickCookerArgs,
        ConfigWatcherMixin,
        LoggerMixin,
        OvenMixin {
  /// {@macro cook_single_brick_command}
  CookSingleBrick(
    this.name,
    this.brick, {
    this.keyPressListener,
  }) {
    argParser
      ..addCookOptionsAndFlags()
      ..addSeparator('${'-' * 79}\n');
  }

  @override
  final String name;

  /// The brick to cook
  final BrickConfig brick;

  @override
  final KeyPressListener? keyPressListener;

  @override
  String get description => 'Cook the brick: $name';

  @override
  Future<int> run() async {
    final result = await putInOven({
      BrickImpl(
        brick,
        name: name,
        outputDir: outputDir,
        watch: isWatch,
        shouldSync: shouldSync,
      ),
    });

    return result.code;
  }
}
