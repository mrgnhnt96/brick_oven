import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/utils/config_watcher_mixin.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:watcher/watcher.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/domain/brick.dart';

/// {@template brick_cooker}
/// A base class for `BrickOvenCommand`s that cook bricks.
/// {@endtemplate}
abstract class BrickCooker with ConfigWatcherMixin {
  /// the logger for output messages
  Logger get logger;

  /// whether to listen to changes to the
  /// [BrickOvenYaml.file] or the [Brick.configPath] file and
  /// the [Brick.source] directory
  bool get isWatch;

  /// the directory to output the brick to
  String get outputDir;

  /// {@macro key_press_listener}
  KeyPressListener get keyPressListener;

  /// the config ([BrickOvenYaml.file] or the [Brick.configPath]) file watcher
  FileWatcher get configWatcher;
}
