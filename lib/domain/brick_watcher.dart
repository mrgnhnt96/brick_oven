// ignore_for_file: must_be_immutable

import 'dart:async';

import 'package:autoequal/autoequal.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:watcher/watcher.dart';

part 'brick_watcher.g.dart';

/// the function that happens on the file event
typedef OnEvent = void Function();

/// {@template brick_watcher}
/// Watches the local files, and updates on events
/// {@endtemplate}
@autoequal
class BrickWatcher extends Equatable {
  /// {@macro brick_watcher}
  BrickWatcher(this.dirPath) : _watcher = DirectoryWatcher(dirPath);

  /// allows to set the watcher
  /// to be used only for testing
  @visibleForTesting
  BrickWatcher.config({
    required this.dirPath,
    required DirectoryWatcher watcher,
  }) : _watcher = watcher;

  /// the source directory of the brick, which will be watched
  final String dirPath;

  @ignoreAutoequal
  final _afterEvents = <OnEvent>[];

  @ignoreAutoequal
  final _beforeEvents = <OnEvent>[];

  @ignoreAutoequal
  final _events = <OnEvent>[];

  @ignoreAutoequal
  var _hasRun = false;

  @ignoreAutoequal
  StreamSubscription<WatchEvent>? _listener;

  /// the source directory of the brick, which will be watched
  @ignoreAutoequal
  final DirectoryWatcher _watcher;

  @override
  List<Object?> get props => _$props;

  /// events to be called after all bricks are cooked
  @visibleForTesting
  List<OnEvent> get afterEvents => List.from(_afterEvents);

  /// events to be called before all bricks are cooked
  @visibleForTesting
  List<OnEvent> get beforeEvents => List.from(_beforeEvents);

  /// events to be called for each brick that gets cooked
  @visibleForTesting
  List<OnEvent> get events => List.from(_events);

  /// whether the watcher has run
  bool get hasRun => _hasRun;

  /// whether the watcher is running
  bool get isRunning =>
      _listener != null &&
      (_events.isNotEmpty ||
          _beforeEvents.isNotEmpty ||
          _afterEvents.isNotEmpty);

  /// the stream subscription for the watcher
  @visibleForTesting
  StreamSubscription<WatchEvent>? get listener => _listener;

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

  /// resets the watcher by stopping it and restarting it
  Future<void> reset() async {
    await _stop(removeEvents: false);

    await start();
  }

  /// starts the watcher
  Future<void> start() async {
    if (_listener != null) {
      return reset();
    }

    _listener = _watcher.events.listen((watchEvent) {
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

    await _watcher.ready;
  }

  /// stops the watcher
  Future<void> stop() => _stop(removeEvents: true);

  /// stops the watcher
  Future<void> _stop({required bool removeEvents}) async {
    await _listener?.cancel();
    _listener = null;

    if (!removeEvents) {
      return;
    }

    _events.clear();
    _beforeEvents.clear();
    _afterEvents.clear();
  }
}
