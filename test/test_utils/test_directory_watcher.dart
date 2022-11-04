import 'dart:async';

import 'package:watcher/watcher.dart';

/// A [DirectoryWatcher] that can be used for testing.
///
/// does not actually listen to file system events, but instead
/// allows you to manually trigger events via [triggerEvent].
class TestDirectoryWatcher implements DirectoryWatcher {
  TestDirectoryWatcher()
      : path = '',
        _controller = StreamController(sync: true);

  @override
  final String path;

  final StreamController<WatchEvent> _controller;

  @override
  Stream<WatchEvent> get events => _controller.stream;

  @override
  String get directory => path;

  @override
  bool get isReady => true;

  @override
  Future<bool> get ready => Future.value(true);

  void close() {
    _controller.close();
  }

  void triggerEvent(WatchEvent event) {
    _controller.add(event);
  }
}
