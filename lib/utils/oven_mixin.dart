// ignore_for_file: overridden_fields

import 'dart:async';
import 'dart:io';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/utils/brick_cooker.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';

/// {@template oven_mixin}
/// A mixin for [BrickOvenCommand]s that cook bricks.
/// {@endtemplate}
mixin OvenMixin on BrickCooker {
  /// {@macro key_press_listener}
  @visibleForTesting
  KeyPressListener get keyListener {
    final listener = keyPressListener;

    if (listener != null) {
      return listener;
    }

    return KeyPressListener(
      stdin: stdin,
      logger: logger,
      toExit: (code) async {
        if (ExitCode.success.code == code) {
          await cancelConfigWatchers(shouldQuit: true);
          return;
        }

        await cancelConfigWatchers(shouldQuit: false);
      },
    );
  }

  /// cooks the [bricks]
  ///
  /// If [isWatch] is true, the [bricks] will be cooked on every change to the
  /// [BrickOvenYaml.file] or [Brick.configPath] and
  /// the [Brick.source] directory/files.
  Future<ExitCode> putInOven(Set<Brick> bricks) async {
    logger.cooking();

    for (final brick in bricks) {
      if (isWatch) {
        brick.source.watcher
          ?..addEvent(
            () => logger.fileChanged(brick.name),
            runBefore: true,
          )
          ..addEvent(logger.cooking, runBefore: true)
          ..addEvent(logger.watching, runAfter: true)
          ..addEvent(logger.keyStrokes, runAfter: true);
      }

      try {
        brick.cook(output: outputDir ?? 'bricks', watch: isWatch);
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

    logger.cooked();

    if (!isWatch) {
      return ExitCode.success;
    }

    logger.watching();

    keyListener.listenToKeystrokes();

    for (final brick in bricks) {
      if (brick.configPath == null) {
        continue;
      }

      unawaited(
        watchForConfigChanges(
          brick.configPath!,
          onChange: () async {
            logger.configChanged();

            await cancelConfigWatchers(shouldQuit: false);
            await brick.source.watcher?.stop();
          },
        ),
      );
    }

    final shouldQuit = await watchForConfigChanges(
      BrickOvenYaml.file,
      onChange: () async {
        logger.configChanged();

        for (final brick in bricks) {
          await brick.source.watcher?.stop();
        }
      },
    );

    if (shouldQuit) {
      return ExitCode.success;
    }

    return ExitCode.tempFail;
  }
}
