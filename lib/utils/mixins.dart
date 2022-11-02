import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:watcher/watcher.dart';

import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/exception.dart';

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
  final Map<String, Completer<void>> _completers = {};

  /// the watcher for the [BrickOvenYaml.file]
  Future<bool> watchForConfigChanges(
    String path, {
    FutureOr<void> Function()? onChange,
  }) async {
    final watchCompleter = Completer<void>();

    final yamlListener = FileWatcher(path).events.listen((event) async {
      await onChange?.call();

      await _cancelWatcher(path);
    });

    await _cancelWatcher(path);

    _completers[path] = watchCompleter;

    await watchCompleter.future;
    await yamlListener.cancel();

    return true;
  }

  /// cancels all watchers
  Future<void> cancelWatchers() async {
    for (final completer in _completers.values) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    _completers.clear();
  }

  /// cancels the watcher for the given [path]
  Future<void> _cancelWatcher(String path) async {
    if (!_completers.containsKey(path)) {
      return;
    }

    final completer = _completers[path]!;
    if (!completer.isCompleted) {
      completer.complete();
    }
    _completers.remove(path);
  }
}
