import 'dart:async';

import 'package:meta/meta.dart';
import 'package:watcher/watcher.dart';

import 'package:brick_oven/domain/brick_oven_yaml.dart';

/// Watches the path provided for changes
mixin ConfigWatcherMixin {
  final Map<String, Completer<bool>> _completers = {};

  /// gets the completers
  @visibleForTesting
  Map<String, Completer<bool>> get completers => {..._completers};

  /// cancels all watchers
  Future<void> cancelConfigWatchers({required bool shouldQuit}) async {
    for (final completer in _completers.values) {
      completer.complete(shouldQuit);
    }

    _completers.clear();
  }

  /// the watcher for the [BrickOvenYaml.file]
  Future<bool> watchForConfigChanges(
    String path, {
    FutureOr<void> Function()? onChange,
  }) async {
    final watchCompleter = Completer<bool>();

    assert(!_completers.containsKey(path), 'Already watching $path');

    final yamlListener = watcher(path).events.listen((event) async {
      await onChange?.call();

      await _cancelWatcher(path, shouldQuit: false);
    });

    await _cancelWatcher(path, shouldQuit: false);

    _completers[path] = watchCompleter;

    final shouldQuit = await watchCompleter.future;
    await yamlListener.cancel();

    return shouldQuit;
  }

  /// Watches the [path] for changes
  @visibleForTesting
  FileWatcher watcher(String path) {
    return FileWatcher(path);
  }

  /// cancels the watcher for the given [path]
  Future<void> _cancelWatcher(String path, {required bool shouldQuit}) async {
    if (!_completers.containsKey(path)) {
      return;
    }

    final completer = _completers[path]!;
    if (!completer.isCompleted) {
      completer.complete(shouldQuit);
    }
    _completers.remove(path);
  }
}
