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

/// the extension for [Logger]
extension LoggerX on Logger {
  /// writes `Cooking...`
  void cooking() {
    info(cyan.wrap('\nCooking...'));
  }

  /// writes `Watching local files...`
  void watching() {
    info(lightYellow.wrap('\nWatching local files...'));
  }

  /// writes `Press q to quit...`
  void qToQuit() {
    info(darkGray.wrap('Press q to quit...'));
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
      help: 'Watch the configuration file for changes and '
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
