import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';

import 'package:brick_oven/utils/extensions/datetime_extensions.dart';

/// the extension for [Logger]
extension LoggerX on Logger {
  /// writes `\n🔥  Preheating...`
  void preheat() {
    info(cyan.wrap('\n🔥  Preheating...'));
  }

  /// writes `Cooked!`
  void dingDing([DateTime? date]) {
    final time = (date ?? DateTime.now()).formatted;

    final cooked = lightGreen.wrap('🔔  Ding Ding! (');
    final timed = darkGray.wrap(time);
    final end = lightGreen.wrap(')');

    info('$cooked$timed$end');
  }

  /// writes `🔧  Configuration changed`
  void configChanged() {
    info('\n🔧  Configuration changed');
  }

  /// writes `📁  File changed (brickName)`
  void fileChanged(String name) {
    info('\n📁  File changed ${darkGray.wrap('($name)')}');
  }

  /// writes the listen to files message
  void watching() {
    info(lightYellow.wrap('\n👀 Watching config & source files...'));
  }

  /// writes the exit message
  void exiting() {
    info('\nExiting...');
  }

  /// writes the restart message
  void restart() {
    info('\nRestarting...');
  }

  /// writes `Press q to quit...`
  void keyStrokes() {
    quit();
    reload();
  }

  /// writes the q to quit message
  @visibleForTesting
  void quit() {
    info(darkGray.wrap('Press q to quit...'));
  }

  /// writes the reload message
  @visibleForTesting
  void reload() {
    info(darkGray.wrap('Press r to reload...'));
  }
}
