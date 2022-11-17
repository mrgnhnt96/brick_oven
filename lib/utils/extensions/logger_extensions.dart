import 'package:brick_oven/utils/extensions/datetime_extensions.dart';
import 'package:mason_logger/mason_logger.dart';

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
  void fileChanged(String brickName) {
    info('\n📁  File changed ${darkGray.wrap('($brickName)')}');
  }

  /// writes `\n👀 Watching local files...`
  void watching() {
    info(lightYellow.wrap('\n👀 Watching config & source files...'));
  }

  /// writes `Press q to quit...`
  void keyStrokes() {
    info(darkGray.wrap('Press q to quit...'));
    info(darkGray.wrap('Press r to reload...'));
  }
}
