import 'dart:async';

import 'package:brick_oven/domain/brick_config.dart';
import 'package:meta/meta.dart';
import 'package:watcher/watcher.dart';

/// the function that happens on the file event
typedef OnEvent = void Function();

/// {@template brick_watcher}
/// Watches the local files, and updates on events
/// {@endtemplate}
class BrickWatcher {
  /// {@macro brick_watcher}
  BrickWatcher(String dir) : watcher = DirectoryWatcher(dir);

  /// the source directory of the brick, which will be watched
  final DirectoryWatcher watcher;

  StreamSubscription<WatchEvent>? _listener;

  /// the stream subscription for the watcher
  @visibleForTesting
  StreamSubscription<WatchEvent>? get listener => _listener;

  final _events = <OnEvent>[];

  /// the list of events to be called on
  @visibleForTesting
  List<OnEvent> get events => List.from(_events);

  /// whether the watcher has run
  bool get hasRun => _hasRun;
  var _hasRun = false;

  /// whether the watcher is running
  bool get isRunning => _listener != null && _events.isNotEmpty;

  /// adds event that will be called when a file creates an event
  void addEvent(OnEvent onEvent) {
    _events.add(onEvent);
  }

  /// starts the watcher
  void start() {
    if (_listener != null) {
      return reset();
    }

    _listener = watcher.events.listen((watchEvent) {
      _hasRun = true;

      logger.info('Running brick_oven...');
      for (final event in _events) {
        event();
      }

      logger.info('\nWatching local files...\n');
    });
  }

  /// resets the watcher by stopping it and restarting it
  void reset() {
    stop();

    start();
  }

  /// stops the watcher
  void stop() {
    _listener?.cancel();
    _listener = null;
  }
}
