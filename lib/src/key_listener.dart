import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import 'package:brick_oven/utils/extensions.dart';

/// quits running the program after `q` is pressed
void qToQuit({Logger? logger}) {
  logger?.qToQuit();

  keyListener(
    keys: <dynamic, void Function()>{
      'q': () async {
        logger?.info('\nExiting...\n');

        exit(ExitCode.success.code);
      },
      // escape key
      0x1b: () {
        logger?.qToQuit();
      },
    },
    logger: logger,
  );
}

/// Returns a stream of keypresses.
void keyListener({
  required Map<dynamic, FutureOr<void> Function()> keys,
  Logger? logger,
}) {
  if (!stdin.hasTerminal) {
    throw StateError('stdin is not a terminal');
  }

  stdin
    ..lineMode = false
    ..echoMode = false
    ..asBroadcastStream(
      onListen: (listener) {
        listener.onData((codes) {
          final key = utf8.decode(codes);

          if (keys.containsKey(key)) {
            keys[key]?.call();
          } else if (keys.containsKey(codes)) {
            keys[codes]?.call();
          } else if (codes.length == 1 && keys.containsKey(codes[0])) {
            keys[codes[0]]?.call();
          }
        });
      },
    );
}
