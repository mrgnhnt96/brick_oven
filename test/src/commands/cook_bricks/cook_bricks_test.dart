import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_bricks.dart';
import 'package:brick_oven/src/runner.dart';
import 'package:usage/usage_io.dart';

import '../../../test_utils/mocks.dart';

void main() {
  late FileSystem fs;
  late CookBricksCommand brickOvenCommand;
  late CommandRunner<void> runner;
  late Logger mockLogger;
  late Analytics mockAnalytics;
  late PubUpdater mockPubUpdater;

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
    mockAnalytics = MockAnalytics();
    mockPubUpdater = MockPubUpdater();

    brickOvenCommand = CookBricksCommand(
      analytics: mockAnalytics,
      fileSystem: fs,
      logger: mockLogger,
    );

    runner = BrickOvenRunner(
      fileSystem: fs,
      logger: mockLogger,
      pubUpdater: mockPubUpdater,
      analytics: mockAnalytics,
    );
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

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockAnalytics);
      verifyNoMoreInteractions(mockPubUpdater);
    });

    test('description displays correctly', () {
      expect(
        brickOvenCommand.description,
        'Cook 👨‍🍳 bricks from the config file',
      );

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockAnalytics);
      verifyNoMoreInteractions(mockPubUpdater);
    });

    test('name is cook', () {
      expect(brickOvenCommand.name, 'cook');

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockAnalytics);
      verifyNoMoreInteractions(mockPubUpdater);
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

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockAnalytics);
      verifyNoMoreInteractions(mockPubUpdater);
    });

    group('when configuration is bad', () {
      late Analytics mockAnalytics;

      setUp(() {
        mockAnalytics = MockAnalytics();

        const badConfig = '';

        when(() => mockAnalytics.firstRun).thenReturn(false);

        when(() => mockAnalytics.sendEvent(any(), any()))
            .thenAnswer((_) => Future.value());
        when(
          () => mockAnalytics.waitForLastPing(timeout: any(named: 'timeout')),
        ).thenAnswer((_) => Future.value());

        fs.file(BrickOvenYaml.file)
          ..createSync()
          ..writeAsStringSync(badConfig);
      });

      test('add usage footer that config is bad', () {
        brickOvenCommand = CookBricksCommand(
          analytics: mockAnalytics,
          fileSystem: fs,
          logger: mockLogger,
        );

        expect(
          brickOvenCommand.usageFooter,
          '\n[WARNING] Unable to load bricks\n'
          'Invalid brick oven configuration file',
        );

        verifyNoMoreInteractions(mockLogger);
        verifyNoMoreInteractions(mockAnalytics);
      });
    });
  });
}
