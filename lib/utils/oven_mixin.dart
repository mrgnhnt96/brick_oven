// ignore_for_file: overridden_fields

import 'dart:async';
import 'dart:io';

import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/domain/interfaces/brick.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/utils/brick_cooker.dart';
import 'package:brick_oven/utils/config_watcher_mixin.dart';
import 'package:brick_oven/utils/extensions/logger_extensions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';

mixin OvenMixin
    on BrickCooker, BrickCookerArgs, ConfigWatcherMixin, LoggerMixin {
  /// {@macro key_press_listener}
  @visibleForTesting
  KeyPressListener get keyListener {
    final listener = keyPressListener;

    if (listener != null) {
      return listener;
    }

    return KeyPressListener(
      stdin: stdin,
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
  /// the [Brick.sourcePath] directory/files.
  Future<ExitCode> putInOven(Set<Brick> bricks) async {
    logger.preheat();

    for (final brick in bricks) {
      if (isWatch) {
        brick.watcher
          ..addEvent(
            logger.fileChanged,
            runBefore: true,
          )
          ..addEvent((_) => logger.preheat(), runBefore: true)
          ..addEvent((_) => logger.dingDing(), runAfter: true)
          ..addEvent((_) => logger.watching(), runAfter: true)
          ..addEvent((_) => logger.keyStrokes(), runAfter: true);
      }

      try {
        brick.cook();
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

    logger.dingDing();

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
            await brick.watcher.stop();
          },
        ),
      );
    }

    final shouldQuit = await watchForConfigChanges(
      BrickOvenYaml.file,
      onChange: () async {
        logger.configChanged();

        for (final brick in bricks) {
          await brick.watcher.stop();
        }
      },
    );

    if (shouldQuit) {
      return ExitCode.success;
    }

    return ExitCode.tempFail;
  }
}
