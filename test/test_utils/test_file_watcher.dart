import 'dart:async';

import 'package:watcher/watcher.dart';

/// A [FileWatcher] that can be used for testing.
///
/// does not actually listen to file system events, but instead
/// allows you to manually trigger events via [triggerEvent].
class TestFileWatcher implements FileWatcher {
  TestFileWatcher()
      : path = '',
        _controller = StreamController(sync: true);

  @override
  final String path;

  StreamController<WatchEvent> _controller;

  @override
  Stream<WatchEvent> get events {
    _controller.add(WatchEvent(ChangeType.ADD, ''));

    return _controller.stream.asBroadcastStream(
      onCancel: (_) {
        _controller.close();
        _controller = StreamController(sync: true);
      },
    );
  }

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
