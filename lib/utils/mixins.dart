import 'dart:async';

import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:meta/meta.dart';
import 'package:watcher/watcher.dart';

/// Watches the path provided for changes
mixin ConfigWatcherMixin {
  final Map<String, Completer<void>> _completers = {};

  /// gets the completers
  @visibleForTesting
  Map<String, Completer<void>> get completers => {..._completers};

  /// cancels all watchers
  Future<void> cancelWatchers() async {
    for (final completer in _completers.values) {
      completer.complete();
    }

    _completers.clear();
  }

  /// the watcher for the [BrickOvenYaml.file]
  Future<void> watchForConfigChanges(
    String path, {
    FutureOr<void> Function()? onChange,
  }) async {
    final watchCompleter = Completer<void>();

    assert(!_completers.containsKey(path), 'Already watching $path');

    final yamlListener = watcher(path).events.listen((event) async {
      await onChange?.call();

      await _cancelWatcher(path);
    });

    await _cancelWatcher(path);

    _completers[path] = watchCompleter;

    await watchCompleter.future;
    await yamlListener.cancel();

    return;
  }

  /// Watches the [path] for changes
  @visibleForTesting
  FileWatcher watcher(String path) {
    return FileWatcher(path);
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
