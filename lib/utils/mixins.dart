import 'dart:async';

import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:watcher/watcher.dart';

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
