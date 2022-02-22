import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:watcher/watcher.dart';

/// the variables for quit after flag
mixin QuitAfterMixin on Command<int> {
  int _updates = 0;

  /// the count of file updates have occurred
  int get updates => _updates;

  /// increments [updates] by 1
  void fileChanged({Logger? logger}) {
    _updates++;
    if (shouldQuit) {
      logger?.info('Quitting after $updates updates');

      throw MaxUpdateException(quitAfter!);
    }
  }

  /// the number of updates that must occur before the command exits
  ///
  /// `null` means that the command will not exit
  int? get quitAfter =>
      _quitAfterArg == null ? null : int.parse(_quitAfterArg!);

  String? get _quitAfterArg => argResults?['quit-after'] as String?;

  /// whether the command should exit based on [updates]
  bool get shouldQuit => quitAfter != null && updates >= quitAfter!;
}

/// Watches the [BrickOvenYaml.file] for changes
mixin ConfigWatcherMixin {
  /// the watcher for the [BrickOvenYaml.file]
  FileWatcher configWatcher = FileWatcher(BrickOvenYaml.file);

  /// the watcher for the [BrickOvenYaml.file]
  Future<bool> watchForConfigChanges({void Function()? onChange}) async {
    final watchCompleter = Completer<void>();

    final _yamlListener = configWatcher.events.listen((event) {
      onChange?.call();

      watchCompleter.complete();
    });

    await watchCompleter.future;
    await _yamlListener.cancel();

    return true;
  }
}
