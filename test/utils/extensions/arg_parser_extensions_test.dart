// ignore_for_file: cascade_invocations

import 'package:args/args.dart';
import 'package:brick_oven/utils/extensions/arg_parser_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('ArgParserX', () {
    late ArgParser argParser;

    setUp(() {
      argParser = ArgParser();
    });

    test('#addCookOptionsAndFlags', () {
      argParser.addCookOptionsAndFlags();

      expect(argParser.options, contains('output'));
      expect(argParser.options, contains('watch'));
      expect(argParser.options, contains('sync'));
    });

    test('#addOutputOption', () {
      argParser.addOutputOption();

      expect(argParser.options, contains('output'));

      final output = argParser.options['output']!;

      expect(output.abbr, 'o');
      expect(output.help, 'Sets the output directory');
      expect(output.valueHelp, 'path');
      expect(output.defaultsTo, 'bricks');
    });

    test('#addSyncFlag', () {
      argParser.addSyncFlag();

      expect(argParser.options, contains('sync'));

      final sync = argParser.options['sync']!;

      expect(sync.abbr, 's');
      expect(
        sync.help,
        'Verifies that the brick.yaml file '
        'is synced with the brick_oven.yaml file.\n'
        'Only works if the `brick_config` key '
        'is set in the brick_oven.yaml file.',
      );
      expect(sync.defaultsTo, true);
    });

    test('#addWatchFlag', () {
      argParser.addWatchFlag();

      expect(argParser.options, contains('watch'));

      final watch = argParser.options['watch']!;

      expect(watch.abbr, 'w');
      expect(watch.negatable, false);
      expect(
        watch.help,
        'Watch for file changes and '
        're-cook the bricks as they change.',
      );
    });
  });
}
