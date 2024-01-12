import 'package:args/command_runner.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_bricks.dart';
import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../../../test_utils/di.dart';

void main() {
  late CookBricksCommand brickOvenCommand;
  late CommandRunner<void> runner;

  setUp(() {
    setupTestDi();

    di<FileSystem>().file(BrickOvenYaml.file)
      ..createSync()
      ..writeAsStringSync(
        '''
bricks:
  first:
    source: path/to/first
  second:
    source: path/to/second
  third:
    source: path/to/third
''',
      );

    brickOvenCommand = CookBricksCommand();

    runner = BrickOvenRunner();
  });

  group('$CookBricksCommand', () {
    test('contains all keys for cook', () {
      expect(
        runner.commands['cook']?.subcommands.keys,
        [
          'all',
          'first',
          'second',
          'third',
        ],
      );

      verifyNoMoreInteractions(di<Logger>());

      verifyNoMoreInteractions(di<PubUpdater>());
    });

    test('description displays correctly', () {
      expect(
        brickOvenCommand.description,
        'Cook 👨‍🍳 bricks from the config file',
      );

      verifyNoMoreInteractions(di<Logger>());

      verifyNoMoreInteractions(di<PubUpdater>());
    });

    test('name is cook', () {
      expect(brickOvenCommand.name, 'cook');

      verifyNoMoreInteractions(di<Logger>());

      verifyNoMoreInteractions(di<PubUpdater>());
    });

    test('contains all sub brick commands', () {
      expect(
        brickOvenCommand.subcommands.keys,
        containsAll([
          'all',
          'first',
          'second',
          'third',
        ]),
      );

      verifyNoMoreInteractions(di<Logger>());

      verifyNoMoreInteractions(di<PubUpdater>());
    });

    group('when configuration is bad', () {
      setUp(() {
        const badConfig = '';

        di<FileSystem>().file(BrickOvenYaml.file)
          ..createSync()
          ..writeAsStringSync(badConfig);
      });

      test('add usage footer that config is bad', () {
        brickOvenCommand = CookBricksCommand();

        expect(
          brickOvenCommand.usageFooter,
          '\n[WARNING] Unable to load bricks\n'
          'Invalid brick oven configuration file',
        );

        verifyNoMoreInteractions(di<Logger>());
      });
    });
  });
}
