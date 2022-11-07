// ignore_for_file: overridden_fields

import 'dart:async';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/brick_cooker.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template oven_mixin}
/// A mixin for [BrickOvenCommand]s that cook bricks.
/// {@endtemplate}
mixin OvenMixin on BrickCooker {
  /// cooks the [bricks]
  ///
  /// If [isWatch] is true, the [bricks] will be cooked on every change to the
  /// [BrickOvenYaml.file] or [Brick.configPath] and
  /// the [Brick.source] directory/files.
  Future<ExitCode> putInOven(Set<Brick> bricks) async {
    logger.cooking();

    if (!isWatch) {
      for (final brick in bricks) {
        brick.cook(output: outputDir);
      }

      logger.cooked();

      return ExitCode.success;
    }

    for (final brick in bricks) {
      brick.source.watcher
        ?..addEvent(
          () => logger.fileChanged(brick.name),
          runBefore: true,
        )
        ..addEvent(logger.cooking, runBefore: true)
        ..addEvent(logger.watching, runAfter: true)
        ..addEvent(logger.keyStrokes, runAfter: true);

      try {
        brick.cook(output: outputDir, watch: true);
      } on ConfigException catch (e) {
        logger
          ..warn(e.message)
          ..err('Could not cook brick: ${brick.name}');

        continue;
      } catch (e) {
        logger
          ..warn('Unknown error: $e')
          ..err('Could not cook brick: ${brick.name}');
        continue;
      }
    }

    logger
      ..cooked()
      ..watching();

    keyPressListener.listenToKeystrokes();

    for (final brick in bricks) {
      if (brick.configPath == null) {
        continue;
      }

      unawaited(
        watchForConfigChanges(
          brick.configPath!,
          onChange: () async {
            logger.configChanged();

            await cancelConfigWatchers();
            await brick.source.watcher?.stop();
          },
        ),
      );
    }

    await watchForConfigChanges(
      BrickOvenYaml.file,
      onChange: () async {
        logger.configChanged();

        for (final brick in bricks) {
          await brick.source.watcher?.stop();
        }
      },
    );

    return ExitCode.tempFail;
  }
}
