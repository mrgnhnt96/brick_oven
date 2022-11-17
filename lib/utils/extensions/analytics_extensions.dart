import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:usage/usage_io.dart';

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
