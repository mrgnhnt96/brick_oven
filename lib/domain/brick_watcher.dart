import 'dart:async';

import 'package:watcher/watcher.dart';

/// the function that happens on the file event
typedef OnEvent = void Function();

/// {@template brick_watcher}
/// Watches the local files of [dir], and updates on events
/// {@endtemplate}
class BrickWatcher {
  /// {@macro brick_watcher}
  BrickWatcher(this.dir);

  /// the source directory of the brick, which will be watched
  final String dir;

  StreamSubscription<WatchEvent>? _watcher;

  final _events = <OnEvent>[];

  /// whether the watcher has run
  bool get hasRun => _hasRun;
  var _hasRun = false;

  /// whether the watcher is running
  bool get isRunning => _watcher != null && _events.isNotEmpty;

  /// adds event that will be called when a file creates an event
  void addEvent(OnEvent onEvent) {
    _events.add(onEvent);
  }

  /// starts the watcher
  void startWatcher() {
    if (_watcher != null) {
      return resetWatcher();
    }

    final watcher = DirectoryWatcher(dir);

    _watcher = watcher.events.listen((e) {
      _hasRun = true;
      print(e);
      for (final event in _events) {
        event();
      }
    });

    // TODO(mrgnhnt96):
    // - add listener to yaml file
    // - update bricks when yaml is updated? Or stop whole process?
    // - refactor listener, and add tests
  }

  /// resets the watcher
  void resetWatcher() {
    _watcher?.cancel();
    _watcher = null;

    startWatcher();
  }
}
