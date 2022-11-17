// ignore_for_file: join_return_with_assignment

import 'package:args/args.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:usage/usage_io.dart';
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

/// extensions for [ArgParser]
extension ArgParserX on ArgParser {
  /// adds the [ArgParser] for `BrickCooker`
  void addCookOptionsAndFlags() {
    addOutputOption();
    addWatchFlag();
    addSyncFlag();
  }

  /// the output directory
  void addOutputOption() {
    addOption(
      'output',
      abbr: 'o',
      help: 'Sets the output directory',
      valueHelp: 'path',
      defaultsTo: 'bricks',
    );
  }

  /// adds the sync flag to validate the brick.yaml file
  void addSyncFlag() {
    addFlag(
      'sync',
      abbr: 's',
      help: 'Verifies that the brick.yaml file '
          'is synced with the brick_oven.yaml file.\n'
          'Only works if the `brick_config` key '
          'is set in the brick_oven.yaml file.',
      defaultsTo: true,
    );
  }

  /// watches the local source files
  void addWatchFlag() {
    addFlag(
      'watch',
      abbr: 'w',
      negatable: false,
      help: 'Watch for file changes and '
          're-cook the bricks as they change.',
    );
  }
}

/// extensions for [Analytics]
extension AnalyticsX on Analytics {
  /// the consent question to ask the user
  @visibleForTesting
  static const ask = '''
+---------------------------------------------------+
|           Welcome to the Brick Oven!              |
+---------------------------------------------------+
| We would like to collect anonymous                |
| usage statistics in order to improve the tool.    |
| Opt-in to help us improve? 🥺 [y/n]               |
+---------------------------------------------------+\n''';

  /// [ask] formatted with colors
  @visibleForTesting
  static String formatAsk() {
    var ask = AnalyticsX.ask;

    ask = ask.replaceAll('Brick Oven', cyan.wrap('Brick Oven')!);
    ask = ask.replaceAll('anonymous', green.wrap('anonymous')!);

    return ask;
  }

  /// the affirmative answer for [ask]
  @visibleForTesting
  static const yes = 'Of course!';

  /// the negative answer for [ask]
  @visibleForTesting
  static const no = 'No thanks.';

  /// asks the user for permission to send analytics
  void askForConsent(Logger logger) {
    if (!firstRun) {
      return;
    }

    final response = logger.chooseOne(
      formatAsk(),
      choices: [yes, no],
      defaultValue: yes,
    );

    enabled = response == yes;
  }
}
