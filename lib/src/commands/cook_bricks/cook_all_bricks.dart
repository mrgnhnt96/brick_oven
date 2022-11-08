import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/brick_oven_cooker.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/utils/config_watcher_mixin.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:brick_oven/utils/oven_mixin.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:watcher/watcher.dart';

/// {@template cook_all_bricks_command}
/// Writes all bricks from the configuration file
/// {@endtemplate}
class CookAllBricks extends BrickOvenCooker with ConfigWatcherMixin, OvenMixin {
  /// {@macro cook_all_bricks_command}
  CookAllBricks({
    FileSystem? fileSystem,
    required Logger logger,
    KeyPressListener? keyPressListener,
  })  : configWatcher = FileWatcher(BrickOvenYaml.file),
        super(fileSystem: fileSystem, logger: logger) {
    argParser
      ..addFlagsAndOptions()
      ..addSeparator('${'-' * 79}\n');

    this.keyPressListener = keyPressListener ??
        keyPressListener ??
        KeyPressListener(
          stdin: stdin,
          logger: logger,
          toExit: (code) async {
            if (ExitCode.tempFail.code == code) {
              await cancelConfigWatchers();
              return;
            }

            exit(code);
          },
        );
  }

  @override
  final FileWatcher configWatcher;

  @override
  late final KeyPressListener keyPressListener;

  @override
  String get description => 'Cook all bricks.';

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

  @override
  bool get isWatch => argResults['watch'] == true;

  @override
  String get outputDir => argResults['output'] as String? ?? 'bricks';
}

extension on ArgParser {
  void addFlagsAndOptions() {
    output();

    watch();

    quitAfter();
  }
}
