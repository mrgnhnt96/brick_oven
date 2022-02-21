import 'dart:async';

import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:watcher/watcher.dart';

/// the function that happens on the file event
typedef OnEvent = void Function();

/// {@template brick_watcher}
/// Watches the local files, and updates on events
/// {@endtemplate}
class BrickWatcher {
  /// {@macro brick_watcher}
  BrickWatcher(this.dirPath, {Logger? logger})
      : watcher = DirectoryWatcher(dirPath),
        logger = logger ?? Logger();

  /// allows to set the watcher
  /// to be used only for testing
  @visibleForTesting
  BrickWatcher.config({
    required this.dirPath,
    required this.watcher,
    Logger? logger,
  }) : logger = logger ?? Logger();

  /// The logger
  final Logger logger;

  /// the source directory of the brick, which will be watched
  final DirectoryWatcher watcher;

  /// the source directory of the brick, which will be watched
  final String dirPath;

  StreamSubscription<WatchEvent>? _listener;

  /// the stream subscription for the watcher
  @visibleForTesting
  StreamSubscription<WatchEvent>? get listener => _listener;

  final _beforeEvents = <OnEvent>[],
      _afterEvents = <OnEvent>[],
      _events = <OnEvent>[];

  /// events to be called for each brick that gets cooked
  @visibleForTesting
  List<OnEvent> get events => List.from(_events);

  /// events to be called after all bricks are cooked
  @visibleForTesting
  List<OnEvent> get afterEvents => List.from(_afterEvents);

  /// events to be called before all bricks are cooked
  @visibleForTesting
  List<OnEvent> get beforeEvents => List.from(_beforeEvents);

  /// whether the watcher has run
  bool get hasRun => _hasRun;
  var _hasRun = false;

  /// whether the watcher is running
  bool get isRunning => _listener != null && _events.isNotEmpty;

  /// adds event that will be called when a file creates an event
  void addEvent(
    OnEvent onEvent, {
    bool runAfter = false,
    bool runBefore = false,
  }) {
    if (runAfter) {
      _afterEvents.add(onEvent);
    } else if (runBefore) {
      _beforeEvents.add(onEvent);
    } else {
      _events.add(onEvent);
    }
  }

  /// starts the watcher
  Future<void> start() async {
    if (_listener != null) {
      return reset();
    }

    _listener = watcher.events.listen((watchEvent) {
      // finishes the watcher
      _hasRun = true;

      for (final event in _beforeEvents) {
        event();
      }

      for (final event in _events) {
        event();
      }

      for (final event in _afterEvents) {
        event();
      }
    });

    await watcher.ready;
  }

  /// resets the watcher by stopping it and restarting it
  Future<void> reset() async {
    await stop();

    await start();
  }

  /// stops the watcher
  Future<void> stop() async {
    await _listener?.cancel();
    _listener = null;
  }
}
