import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/src/version.dart';
import 'package:brick_oven/utils/extensions/analytics_extensions.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';
import 'package:usage/usage_io.dart';

import '../test_utils/mocks.dart';
import '../test_utils/print_override.dart';

const expectedUsage = '''
Generate your bricks 🧱 with this oven 🎛

Usage: brick_oven <command> [arguments]

Global options:
-h, --help           Print this usage information.
    --version        Print the current version
    --analytics      Toggle anonymous usage statistics.

          [false]    Disable anonymous usage statistics
          [true]     Enable anonymous usage statistics

Available commands:
  cook     Cook 👨‍🍳 bricks from the config file
  list     Lists all configured bricks from brick_oven.yaml
  update   Updates brick_oven to the latest version

Run "brick_oven help <command>" for more information about a command.''';

void main() {
  group('$BrickOvenRunner', () {
    late Logger mockLogger;
    late PubUpdater mockPubUpdater;
    late Analytics mockAnalytics;
    late BrickOvenRunner commandRunner;
    late FileSystem fs;

    setUp(() {
      printLogs = [];

      mockLogger = MockLogger();
      mockPubUpdater = MockPubUpdater();
      mockAnalytics = MockAnalytics()..stubMethods();
      fs = MemoryFileSystem();

      fs.file(BrickOvenYaml.file)
        ..createSync(recursive: true)
        ..writeAsStringSync('bricks:');

      when(
        () => mockPubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) => Future.value(packageVersion));

      commandRunner = BrickOvenRunner(
        logger: mockLogger,
        pubUpdater: mockPubUpdater,
        fileSystem: fs,
        analytics: mockAnalytics,
      );
    });

    test('time out is correct duration', () {
      expect(BrickOvenRunner.timeout, const Duration(milliseconds: 500));
    });

    group('run', () {
      group('analytics', () {
        test('can be enabled', () async {
          commandRunner = BrickOvenRunner(
            logger: mockLogger,
            pubUpdater: mockPubUpdater,
            fileSystem: fs,
            analytics: mockAnalytics,
          );

          final result = await commandRunner.run(['--analytics', 'true']);

          verify(() => mockAnalytics.enabled = true).called(1);

          verify(() => mockLogger.info('analytics enabled.')).called(1);

          expect(result, ExitCode.success.code);
        });

        test('can be disabled', () async {
          final analytics = MockAnalytics();

          commandRunner = BrickOvenRunner(
            logger: mockLogger,
            pubUpdater: mockPubUpdater,
            fileSystem: fs,
            analytics: analytics,
          );

          final result = await commandRunner.run(['--analytics', 'false']);

          verify(() => analytics.enabled = false).called(1);

          verify(() => mockLogger.info('analytics disabled.')).called(1);

          expect(result, ExitCode.success.code);
        });

        test('asks for consent when first time running', () async {
          final mockAnalytics = MockAnalytics();

          when(() => mockAnalytics.firstRun).thenReturn(true);

          commandRunner = BrickOvenRunner(
            logger: mockLogger,
            pubUpdater: mockPubUpdater,
            fileSystem: fs,
            analytics: mockAnalytics,
          );

          await commandRunner.run([]);

          verify(() => mockAnalytics.askForConsent(mockLogger)).called(1);

          verify(
            () => mockLogger.chooseOne(
              AnalyticsX.formatAsk(),
              choices: [AnalyticsX.yes, AnalyticsX.no],
              defaultValue: AnalyticsX.yes,
            ),
          ).called(1);
        });
      });

      test('handles $FormatException', () async {
        const exception = FormatException('oops!');

        final commandRunner = TestBrickOvenRunner(
          logger: mockLogger,
          fileSystem: fs,
          onRun: () {
            throw exception;
          },
        );

        final result = await commandRunner.run([]);

        expect(result, ExitCode.usage.code);

        verify(() => mockLogger.err(exception.message)).called(1);
        verify(() => mockLogger.info('\n${commandRunner.usage}')).called(1);
      });

      test('handles $UsageException', () async {
        final exception = UsageException('oops!', 'usage');

        final commandRunner = TestBrickOvenRunner(
          logger: mockLogger,
          fileSystem: fs,
          onRun: () {
            throw exception;
          },
        );

        final result = await commandRunner.run([]);

        expect(result, ExitCode.usage.code);

        verify(() => mockLogger.err(exception.message)).called(1);
        verify(() => mockLogger.info('\n${commandRunner.usage}')).called(1);
      });

      test('handles other exceptions', () async {
        final exception = Exception('oops!');

        final commandRunner = TestBrickOvenRunner(
          logger: mockLogger,
          fileSystem: fs,
          onRun: () {
            throw exception;
          },
        );

        final result = await commandRunner.run([]);

        expect(result, ExitCode.software.code);

        verify(() => mockLogger.err('$exception')).called(1);
      });

      test('handles no command', () async {
        await overridePrint(() async {
          final result = await commandRunner.run([]);

          expect(printLogs, equals([expectedUsage]));
          expect(result, equals(ExitCode.success.code));
        });
      });

      group('help', () {
        test(
          '--help outputs usage',
          () async {
            await overridePrint(() async {
              final result = await commandRunner.run(['--help']);

              expect(printLogs, [expectedUsage]);
              expect(result, ExitCode.success.code);
            });
          },
        );

        test(
          '-h outputs usage',
          () {
            overridePrint(() async {
              final resultAbbr = await commandRunner.run(['-h']);

              expect(printLogs, [expectedUsage]);
              expect(resultAbbr, ExitCode.success.code);
            });
          },
        );
      });

      test('--version outputs current version', () async {
        final result = await commandRunner.run(['--version']);

        expect(result, ExitCode.success.code);
        verify(() => mockLogger.alert(packageVersion)).called(1);
      });

      group('#checkForUpdates', () {
        test('when analytics command is provided', () async {
          await commandRunner.run(['--analytics', 'true']);

          verify(() => mockPubUpdater.getLatestVersion(any())).called(1);
        });

        test('when version command is provided', () async {
          await commandRunner.run(['--version']);

          verify(() => mockPubUpdater.getLatestVersion(any())).called(1);
        });

        test('when other command is provided', () async {
          await commandRunner.run(['list']);

          verify(() => mockPubUpdater.getLatestVersion(any())).called(1);
        });

        test('not when update command is provided', () async {
          await commandRunner.run(['update']);

          // this succeeds because mockLogger is not stubbing `progress` which is causing
          // an exception to be thrown. Meaning that `getLatestVersion` is never called
          verifyNever(() => mockPubUpdater.getLatestVersion(any()));
        });
      });
    });
  });
}

class TestBrickOvenRunner extends BrickOvenRunner {
  TestBrickOvenRunner({
    required Logger logger,
    required FileSystem fileSystem,
    required this.onRun,
  }) : super(
          logger: logger,
          pubUpdater: MockPubUpdater(),
          fileSystem: fileSystem,
          analytics: MockAnalytics(),
        );

  final void Function() onRun;

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    onRun();

    return 0;
  }
}
