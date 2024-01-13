import 'package:args/command_runner.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:mason_logger/mason_logger.dart';

import 'package:brick_oven/domain/take_2/brick_config.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/key_press_listener.dart';

/// The base command for logger
mixin LoggerMixin {
  /// the logger for output messages
  Logger get logger => di<Logger>();
}

/// {@template brick_cooker}
/// A base class for `BrickOvenCommand`s that cook bricks.
/// {@endtemplate}
mixin BrickCooker {
  /// {@macro key_press_listener}
  KeyPressListener? get keyPressListener;
}

/// {@template brick_cooker_args}
/// The args for a [BrickCooker].
/// {@endtemplate}
mixin BrickCookerArgs on Command<int> {
  /// whether to listen to changes to the
  /// [BrickOvenYaml.file] or the [BrickConfig.configPath] file and
  /// the [BrickConfig.sourcePath] directory
  bool get isWatch => argResults?['watch'] as bool? ?? false;

  /// whether to validate if the brick.yaml file is synced
  bool get shouldSync => argResults?['sync'] as bool? ?? true;

  /// the directory to output the brick to
  String? get outputDir => argResults?['output'] as String?;
}
