import 'package:args/args.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

/// the extension for [YamlMap]

extension YamlMapX on YamlMap {
  /// returns a modifiable Map of the[value]
  Map<String, dynamic> get data {
    return Map<String, dynamic>.from(value);
  }
}

extension _NumX on num {
  String get padded => toString().padLeft(2, '0');

  String get to12Hour {
    final hour = this % 12;
    return hour == 0 ? '12' : hour.toString();
  }

  String get meridiem => this >= 12 ? 'PM' : 'AM';
}

/// the extension for [DateTime]
extension DateTimeX on DateTime {
  /// returns a string representation of the [DateTime]
  String get formatted {
    final hour = this.hour.to12Hour;
    final minute = this.minute.padded;
    final second = this.second.padded;
    final meridiem = this.hour.meridiem;

    return '$hour:$minute:$second $meridiem';
  }
}

/// the extension for [Logger]
extension LoggerX on Logger {
  /// writes `\n⏲️  Cooking...`
  void cooking() {
    info(cyan.wrap('\n⏲️  Cooking...'));
  }

  /// writes `Cooked!`
  void cooked([DateTime? date]) {
    final time = (date ?? DateTime.now()).formatted;

    final cooked = lightGreen.wrap('\n🍽️  Cooked! (');
    final timed = darkGray.wrap(time);
    final end = lightGreen.wrap(')');

    info('$cooked$timed$end\n');
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
    info(lightYellow.wrap('\n👀 Watching local files...'));
  }

  /// writes `Press q to quit...`
  void keyStrokes() {
    info(darkGray.wrap('Press q to quit...'));
    info(darkGray.wrap('Press r to reload...'));
  }
}

/// extensions for [ArgParser]
extension ArgParserX on ArgParser {
  /// the output directory
  void output() {
    addOption(
      'output',
      abbr: 'o',
      help: 'Sets the output directory',
      valueHelp: 'path',
      defaultsTo: 'bricks',
    );
  }

  /// watches the local source files
  void watch() {
    addFlag(
      'watch',
      abbr: 'w',
      negatable: false,
      help: 'Watch for file changes and '
          're-cook the bricks as they change.',
    );
  }

  /// quits after x file updates
  void quitAfter() {
    addOption(
      'quit-after',
      abbr: 'x',
      help: 'Quit after the specified number of updates.',
      hide: true,
    );
  }
}
