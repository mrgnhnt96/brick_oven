import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_bricks.dart';
import 'package:brick_oven/src/runner.dart';

import '../../../test_utils/mocks.dart';

void main() {
  late FileSystem fs;
  late CookBricksCommand brickOvenCommand;
  late CommandRunner<void> runner;
  late Logger mockLogger;

  setUp(() {
    fs = MemoryFileSystem();
    fs.file(BrickOvenYaml.file)
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
    mockLogger = MockLogger();
    brickOvenCommand = CookBricksCommand(
      analytics: MockAnalytics(),
      fileSystem: fs,
      logger: mockLogger,
    );
    runner = BrickOvenRunner(
      fileSystem: fs,
      logger: mockLogger,
      pubUpdater: MockPubUpdater(),
      analytics: MockAnalytics(),
    );
  });

  group('$CookBricksCommand', () {
    test('instanciate without an explicit file system or logger', () {
      expect(
        () => CookBricksCommand(
          analytics: MockAnalytics(),
          fileSystem: fs,
          logger: mockLogger,
        ),
        returnsNormally,
      );
    });

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
    });

    test('description displays correctly', () {
      expect(
        brickOvenCommand.description,
        'Cook 👨‍🍳 bricks from the config file',
      );
    });

    test('name is cook', () {
      expect(brickOvenCommand.name, 'cook');
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
    });

    group('when configuration is bad', () {
      setUp(() {
        const badConfig = '';

        fs.file(BrickOvenYaml.file)
          ..createSync()
          ..writeAsStringSync(badConfig);
      });

      test('logs that config is bad', () {
        brickOvenCommand = CookBricksCommand(
          analytics: MockAnalytics(),
          fileSystem: fs,
          logger: mockLogger,
        );

        verify(() => mockLogger.warn(any())).called(1);

        verify(() => mockLogger.err('Error reading ${BrickOvenYaml.file}'))
            .called(1);
      });
    });
  });
}
