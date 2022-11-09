import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import 'package:brick_oven/utils/extensions.dart';
import 'package:meta/meta.dart';

/// Type of Map<dynamic, void Function()>
typedef KeyMap = Map<dynamic, FutureOr<void> Function()>;

/// {@template key_press_listener}
/// A class that listens for key presses from [stdin]
/// and emits the key presses to the stream.
/// {@endtemplate}
class KeyPressListener {
  /// {@macro key_press_listener}
  KeyPressListener({
    required Stdin stdin,
    required this.toExit,
    required Logger logger,
  })  : _stdin = stdin,
        _logger = logger;

  /// the listener of key presses
  static StreamSubscription<List<int>>? _listener;

  /// we only need one stream for stdin
  static Stream<List<int>>? _stream;

  final Logger _logger;
  final Stdin _stdin;

  /// the method to call when a key is pressed
  @visibleForTesting
  final FutureOr<void> Function(int) toExit;

  /// The key presses that can be detected.
  @visibleForTesting
  // ignore: unnecessary_cast
  KeyMap get keyPresses => {
        'q': () {
          _logger.info('\nExiting...');

          toExit(ExitCode.success.code);
        },
        'r': () {
          _listener?.cancel();
          _logger.info('\nRestarting...');

          toExit(ExitCode.tempFail.code);
        },
        // escape key
        0x1b: _logger.keyStrokes,
      } as KeyMap;

  /// Returns a stream of keypresses.
  @visibleForTesting
  void keyListener({required KeyMap keys}) {
    if (!_stdin.hasTerminal) {
      throw StateError('stdin does not have terminal');
    }

    _stdin
      ..lineMode = false
      ..echoMode = false;

    _listener?.cancel();

    _stream ??= _stdin.asBroadcastStream();
    _listener = _stream!.listen((codes) {
      onListen(codes, keys);
    });
  }

  /// listens to keystrokes and handles them with the [keyPresses] map.
  void listenToKeystrokes() {
    if (!_stdin.hasTerminal) {
      return;
    }

    _logger.keyStrokes();

    keyListener(keys: keyPresses);
  }

  /// listens for keypresses
  @visibleForTesting
  void onListen(List<int> codes, Map<dynamic, FutureOr<void> Function()> keys) {
    final key = utf8.decode(codes);

    if (keys.containsKey(key)) {
      keys[key]?.call();
    } else if (codes.length == 1 && keys.containsKey(codes[0])) {
      keys[codes[0]]?.call();
    }
  }
}
